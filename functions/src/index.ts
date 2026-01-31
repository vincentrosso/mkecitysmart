import {
  onDocumentCreated,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {
  FieldValue,
  GeoPoint,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

type DevicePlatform = "ios" | "android" | "web" | "unknown";

type ApprovalTier = "auto" | "soft" | "manual";
type AlertStatus = "active" | "pending" | "rejected";

type RegisterDeviceRequest = {
  token: string;
  platform?: DevicePlatform;
  latitude?: number;
  longitude?: number;
  locationPrecisionMeters?: number;
  radiusMiles?: number;
};

type DeviceDoc = {
  uid: string;
  token: string;
  platform: DevicePlatform;
  // Optional last known location
  location?: GeoPoint;
  geohash?: string;
  locationPrecisionMeters?: number | null;
  radiusMiles?: number;
  // Auditing
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastSeenAt: Timestamp;
};

const DEFAULT_NEARBY_RADIUS_MILES = 5;
const MAX_NEARBY_RADIUS_MILES = 25;
const MAX_FANOUT_PER_SIGHTING = 2000;
const MAX_CANDIDATE_SCAN = 5000;
const MULTICAST_CHUNK_SIZE = 500;

// Approval tiers
const SOFT_AUTO_APPROVE_DELAY_MINUTES = 3;

// Abuse controls
const IP_RATE_LIMIT_MAX = 8;
const IP_RATE_LIMIT_WINDOW_SECONDS = 10 * 60;
const DUPLICATE_TEXT_WINDOW_MINUTES = 30;
const DUPLICATE_TEXT_MAX = 2;

const haversineMiles = (
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
) => {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const r = 3958.8;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return r * c;
};

const approxBoundingBoxDegrees = (radiusMiles: number) => {
  // Rough bounding box to reduce candidates before haversine.
  // 1 degree latitude ~= 69 miles.
  const latDelta = radiusMiles / 69;
  // Longitude delta depends on latitude; caller should divide by cos(lat).
  return {latDelta};
};

// --- Geohash helpers (no external deps) ---
// Base32 alphabet used by standard geohash.
const GEOHASH_BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

const encodeGeohash = (lat: number, lon: number, precision = 8): string => {
  // Typical precisions:
  // 7 ~ 0.15km, 8 ~ 0.02km (varies by latitude)
  // We mainly use this for prefiltering; final haversine correctness is preserved.
  let idx = 0;
  let bit = 0;
  let evenBit = true;
  let geohash = "";

  let latMin = -90.0;
  let latMax = 90.0;
  let lonMin = -180.0;
  let lonMax = 180.0;

  while (geohash.length < precision) {
    if (evenBit) {
      const lonMid = (lonMin + lonMax) / 2;
      if (lon >= lonMid) {
        idx = (idx << 1) + 1;
        lonMin = lonMid;
      } else {
        idx = (idx << 1) + 0;
        lonMax = lonMid;
      }
    } else {
      const latMid = (latMin + latMax) / 2;
      if (lat >= latMid) {
        idx = (idx << 1) + 1;
        latMin = latMid;
      } else {
        idx = (idx << 1) + 0;
        latMax = latMid;
      }
    }

    evenBit = !evenBit;
    if (++bit === 5) {
      geohash += GEOHASH_BASE32.charAt(idx);
      bit = 0;
      idx = 0;
    }
  }

  return geohash;
};

const geohashPrecisionForRadiusMiles = (radiusMiles: number): number => {
  // Choose a geohash precision that keeps the number of candidate docs reasonable.
  // This is heuristic; we still do haversine filtering afterwards.
  if (radiusMiles <= 1) return 7;
  if (radiusMiles <= 5) return 6;
  if (radiusMiles <= 10) return 5;
  return 5;
};

const geohashQueryRanges = (centerGeohash: string, prefixLen: number) => {
  // Range query for all strings with the same prefix:
  // [prefix, prefix + "\uf8ff"]
  //
  // NOTE: true neighbor-cell coverage is more complex. To reduce boundary misses
  // without an external geohash-neighbors implementation, we widen the prefix
  // by one character (coarser cell), which increases candidate coverage and
  // relies on haversine filtering for correctness.
  const effectivePrefixLen = Math.max(1, prefixLen - 1);
  const prefix = centerGeohash.slice(0, effectivePrefixLen);
  return [{start: prefix, end: prefix + "\uf8ff"}];
};

const chunk = <T>(arr: T[], size: number): T[][] => {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
};

const determineApprovalTier = (report: {
  reporterUid: string;
  notes: string;
  hasGeo: boolean;
}): {tier: ApprovalTier; reviewReason?: string} => {
  // IMPORTANT: Server-owned decision. Client must never provide approval tier.
  // Heuristics (safe defaults):
  // - manual: lots of text or missing geo (harder to verify / higher abuse risk)
  // - soft: normal reports with geo
  // - auto: trusted reporters or very short well-formed reports (placeholder logic)

  const notes = (report.notes ?? "").toString();
  const hasUrl = /http(s)?:\/\//i.test(notes);
  const tooLong = notes.length >= 250;
  const repeatedChars = /(.)\1{8,}/.test(notes);
  const emojiHeavy = ((notes.match(/[\u{1F300}-\u{1FAFF}]/gu) ?? []).length / Math.max(1, notes.length)) > 0.05;
  const looksSpammy = hasUrl || tooLong || repeatedChars || emojiHeavy;

  if (!report.hasGeo) {
    // Missing geo can't do precise nearby fanout (and is harder to validate),
    // but we still want the community signal to flow with minimal moderation.
    // Use soft tier so it becomes visible after a short delay if it isn't flagged.
    // If it's spammy, go manual.
    if (looksSpammy) {
      return {tier: "manual", reviewReason: "missing_location_needs_review"};
    }
    return {tier: "soft", reviewReason: "missing_location"};
  }

  if (looksSpammy) {
    return {tier: "manual", reviewReason: "needs_review"};
  }

  // Default: minimize manual approvals.
  // Anything geo-present and not obviously spam is auto-approved.
  return {tier: "auto"};
};

// Initialize with default credentials - Cloud Functions provides these automatically
admin.initializeApp();

// Define a secret reference for service account key
import {defineSecret} from "firebase-functions/params";
import {GoogleAuth} from "google-auth-library";
const firebaseAdminSdkKey = defineSecret("firebase-adminsdk-key");

// FCM helper using direct HTTP API to avoid OAuth issues with default credentials
// This requires the secret to be available in the function's runtime
interface FcmSendResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

// Helper for FCM - exported for potential future use or testing
export const sendFcmMessage = async (
  secretValue: string,
  message: {
    token?: string;
    topic?: string;
    notification: {title: string; body: string};
    data?: Record<string, string>;
  }
): Promise<FcmSendResult> => {
  try {
    const serviceAccountKey = JSON.parse(secretValue);
    const auth = new GoogleAuth({
      credentials: serviceAccountKey,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = await auth.getAccessToken();

    const fcmMessage: any = {
      notification: message.notification,
    };
    if (message.token) {
      fcmMessage.token = message.token;
    }
    if (message.topic) {
      fcmMessage.topic = message.topic;
    }
    if (message.data) {
      fcmMessage.data = message.data;
    }

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccountKey.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({message: fcmMessage}),
      }
    );

    const result = await response.json();
    if (response.ok) {
      return {success: true, messageId: result.name};
    } else {
      return {success: false, error: JSON.stringify(result)};
    }
  } catch (err) {
    return {success: false, error: err instanceof Error ? err.message : String(err)};
  }
};

// Multicast version for sending to multiple tokens - exported for potential future use
export const sendFcmMulticast = async (
  secretValue: string,
  tokens: string[],
  notification: {title: string; body: string},
  data?: Record<string, string>
): Promise<{successCount: number; failureCount: number; invalidTokens: string[]}> => {
  const serviceAccountKey = JSON.parse(secretValue);
  const auth = new GoogleAuth({
    credentials: serviceAccountKey,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const accessToken = await auth.getAccessToken();

  let successCount = 0;
  let failureCount = 0;
  const invalidTokens: string[] = [];

  for (const token of tokens) {
    try {
      const fcmMessage: any = {token, notification};
      if (data) {
        fcmMessage.data = data;
      }

      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccountKey.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({message: fcmMessage}),
        }
      );

      if (response.ok) {
        successCount++;
      } else {
        failureCount++;
        const errBody = await response.text();
        if (errBody.includes("UNREGISTERED") || errBody.includes("INVALID_ARGUMENT")) {
          invalidTokens.push(token);
        }
      }
    } catch {
      failureCount++;
    }
  }

  return {successCount, failureCount, invalidTokens};
};

export const mirrorUserSightingToGlobal = onDocumentCreated(
  "users/{uid}/sightings/{sightingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const uid = event.params.uid as string;
    const sightingId = event.params.sightingId as string;

    const data = (snap.data() as any) ?? null;
    if (!data) {
      logger.warn("mirrorUserSightingToGlobal missing data", {
        sightingId,
        uid,
        sourcePath: snap.ref.path,
      });
      return;
    }
    const db = getFirestore();

    const now = Timestamp.now();
    const timestamp = data.timestamp ?? FieldValue.serverTimestamp();
    const merged = {
      ...data,
      uid: data?.uid ?? uid,
      status: data?.status ?? "active",
      createdAt: data?.createdAt ?? now,
      timestamp,
      expiresAt:
        data?.expiresAt ??
        Timestamp.fromMillis(now.toMillis() + 2 * 60 * 60 * 1000),
      sourcePath: snap.ref.path,
      mirroredAt: now,
    };

    await db.collection("sightings").doc(sightingId).set(merged, {merge: true});
  }
);

export const helloWorld = onRequest((req, res) => {
  logger.info("helloWorld hit", {method: req.method, path: req.path});
  res.status(200).send("Hello from Firebase Functions!");
});

export const cleanupExpiredSightings = onSchedule("every 5 minutes", async () => {
  const db = getFirestore();
  const now = Timestamp.now();

  const queries = [
    db
        .collectionGroup("sightings")
        .where("status", "==", "active")
        .where("expiresAt", "<=", now),
    db
        .collection("live_sightings")
        .where("status", "==", "active")
        .where("expiresAt", "<=", now),
  ];

  const snaps = await Promise.all(queries.map((q) => q.get()));
  let total = 0;
  const batch = db.batch();

  for (const snap of snaps) {
    snap.docs.forEach((doc) => {
      total++;
      batch.update(doc.ref, {
        status: "expired",
        expiredAt: now,
      });
    });
  }

  if (total === 0) return;

  await batch.commit();
});

export const mirrorSightingsToAlerts = onDocumentWritten(
  "sightings/{sightingId}",
  async (event) => {
    const db = getFirestore();
    const sightingId = event.params.sightingId as string;
    const after = event.data?.after;

    // Delete mirrored alert if the sighting was removed.
    if (after == null || !after.exists) {
      await db
        .collection("alerts")
        .doc(sightingId)
        .delete()
        .catch(() => {});
      return;
    }

    const data = (after.data() as any) ?? {};
    const type = (data.type ?? "").toString().toLowerCase();
    const isTow = type === "tow" || type === "towtruck";
    const loc = (data.location ?? "Nearby").toString();

    const title = data.title ?? (isTow ? "Tow sighting" : "Enforcer sighting");
    const message = data.message ??
        (isTow
            ? `Tow trucks spotted near ${loc}.`
            : `Enforcer spotted near ${loc}.`);

    const now = Timestamp.now();
    const createdAt = data.createdAt ?? now;
    const expiresAt = data.expiresAt ?? null;

    const status = (data.status ?? "active").toString().toLowerCase();
    const isActive = status == "active";
    const alertDoc = {
      sourceType: "sighting",
      sourceId: sightingId,
      sightingId,
      type: isTow ? "tow" : "enforcer",
      title,
      message,
      location: loc,
      latitude: data.latitude ?? null,
      longitude: data.longitude ?? null,
      createdAt,
      expiresAt,
      status: isActive ? "active" : "inactive",
      active: isActive,
      sourcePath: after.ref.path,
      mirroredAt: FieldValue.serverTimestamp(),
    };

    await db.collection("alerts").doc(sightingId).set(alertDoc, {merge: true});
  },
);

const RATE_LIMIT_MAX = 3;
const RATE_LIMIT_WINDOW_SECONDS = 60 * 60;

export const submitSighting = onCall(async (request) => {
  const uidBase =
    request.auth?.uid ?? `anonymous_${request.rawRequest.ip ?? "unknown"}`;
  const uidKey = uidBase.replace(/[^A-Za-z0-9_.-]/g, "_");

  const ip = (request.rawRequest.ip ?? "unknown").toString();
  const ipKey = `ip_${ip}`.replace(/[^A-Za-z0-9_.-]/g, "_");

  const db = getFirestore();
  const now = Timestamp.now();
  const rateRef = db.collection("rate_limits").doc(uidKey);
  const ipRateRef = db.collection("rate_limits").doc(ipKey);

  const allowed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(rateRef);
    const data = snap.data() as {count?: number; windowStart?: Timestamp} | undefined;
    const windowStart = data?.windowStart ?? now;
    const elapsed =
      now.toMillis() - windowStart.toMillis();

    if (!snap.exists || elapsed >= RATE_LIMIT_WINDOW_SECONDS * 1000) {
      tx.set(rateRef, {count: 1, windowStart: now});
      return true;
    }

    const count = data?.count ?? 0;
    if (count >= RATE_LIMIT_MAX) return false;

    tx.update(rateRef, {count: count + 1});
    return true;
  });

  const ipAllowed = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ipRateRef);
    const data = snap.data() as {count?: number; windowStart?: Timestamp} | undefined;
    const windowStart = data?.windowStart ?? now;
    const elapsed = now.toMillis() - windowStart.toMillis();

    if (!snap.exists || elapsed >= IP_RATE_LIMIT_WINDOW_SECONDS * 1000) {
      tx.set(ipRateRef, {count: 1, windowStart: now});
      return true;
    }

    const count = data?.count ?? 0;
    if (count >= IP_RATE_LIMIT_MAX) return false;

    tx.update(ipRateRef, {count: count + 1});
    return true;
  });

  if (!allowed || !ipAllowed) {
    throw new HttpsError(
      "resource-exhausted",
      "Rate limit exceeded. Try again later.",
    );
  }

  const location = (request.data?.location ?? "").toString().trim();
  const notes = (request.data?.notes ?? "").toString();
  const isEnforcer = Boolean(request.data?.isEnforcer);
  const latitude = Number(request.data?.latitude);
  const longitude = Number(request.data?.longitude);
  const hasGeo = Number.isFinite(latitude) && Number.isFinite(longitude);

  if (!location || notes.length > 500) {
    throw new HttpsError("invalid-argument", "Invalid report");
  }

  // Duplicate-content abuse signal (same text repeated across a short window).
  // If tripped, we downgrade from auto -> soft/manual.
  const notesKey = notes
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 200);

  let duplicateTextCount = 0;
  if (notesKey.length > 0 && request.auth?.uid) {
    const since = Timestamp.fromMillis(Date.now() - DUPLICATE_TEXT_WINDOW_MINUTES * 60 * 1000);
    const dupSnap = await db
      .collection("alerts")
      .where("reporterUid", "==", request.auth.uid)
      .where("createdAt", ">=", since)
      .limit(25)
      .get()
      .catch(() => null);

    if (dupSnap) {
      duplicateTextCount = dupSnap.docs
        .map((d) => ((d.data() as any)?.message ?? "").toString().toLowerCase().replace(/\s+/g, " ").trim().slice(0, 200))
        .filter((m) => m === notesKey).length;
    }
  }

  const alertRef = db.collection("alerts").doc();

  let approvalDecision = determineApprovalTier({
    reporterUid: uidBase,
    notes,
    hasGeo,
  });

  // If the user is repeating the same content, force review.
  if (duplicateTextCount >= DUPLICATE_TEXT_MAX) {
    approvalDecision = {tier: "manual", reviewReason: "duplicate_content"};
  }

  const approvalTier: ApprovalTier = approvalDecision.tier;
  const initialStatus: AlertStatus = approvalTier === "auto" ? "active" : "pending";
  const initialActive = initialStatus === "active";

  await alertRef.set({
    title: isEnforcer ? "Enforcement Sighting" : "Tow Sighting",
    message: notes || "No notes",
    location,
    type: isEnforcer ? "enforcer" : "tow",
    approvalTier,
    reviewReason: approvalDecision.reviewReason ?? null,
    status: initialStatus,
    active: initialActive,
    createdAt: FieldValue.serverTimestamp(),
    timestamp: FieldValue.serverTimestamp(),
    source: isEnforcer ? "parking_enforcer" : "tow_truck",
    reporterUid: uidBase,
    isPublic: false,
    geo: hasGeo ? new GeoPoint(latitude, longitude) : null,
    flagged: false,
    softApproveAfter: approvalTier === "soft"
      ? Timestamp.fromMillis(Date.now() + SOFT_AUTO_APPROVE_DELAY_MINUTES * 60 * 1000)
      : null,
  });

  logger.info("submitSighting created alert", {alertId: alertRef.id, uid: uidBase});

  // Immediate nearby-user push fan-out when geo is available.
  // Only do this when we decide the report does NOT require manual review.
  if (hasGeo && approvalTier !== "manual") {
    try {
      const reporterUid = uidBase;
      const radiusMiles = Math.min(
        Math.max(Number(request.data?.radiusMiles ?? DEFAULT_NEARBY_RADIUS_MILES), 0.1),
        MAX_NEARBY_RADIUS_MILES,
      );

      const devicesRef = db.collection("devices");

      const precision = geohashPrecisionForRadiusMiles(radiusMiles);
      const centerHash = encodeGeohash(latitude, longitude, 8);
      const ranges = geohashQueryRanges(centerHash, precision);

      const {latDelta} = approxBoundingBoxDegrees(radiusMiles);
      const latMin = latitude - latDelta;
      const latMax = latitude + latDelta;
      // Avoid huge lon deltas near the poles; Milwaukee is fine but keep safe.
      const cosLat = Math.max(0.2, Math.cos((latitude * Math.PI) / 180));
      const lonDelta = radiusMiles / (69 * cosLat);
      const lonMin = longitude - lonDelta;
      const lonMax = longitude + lonDelta;

      // Query by geohash prefix/range to avoid scanning the whole devices collection.
      // Note: We currently query only the center geohash prefix. For larger radii,
      // we may need to query neighboring prefixes (follow-up improvement).
      const candidateDocs: Array<{id: string; data: any}> = [];
      for (const r of ranges) {
        const snap = await devicesRef
          .where("geohash", ">=", r.start)
          .where("geohash", "<=", r.end)
          .limit(MAX_CANDIDATE_SCAN)
          .get();
        snap.docs.forEach((d) => candidateDocs.push({id: d.id, data: d.data() as any}));
      }

      const candidates = candidateDocs
        .filter(({data}) => (data.uid ?? "").toString() !== reporterUid)
        .filter(({data}) => {
          const gp = data.location as GeoPoint | undefined;
          if (!gp) return false;
          const lat = Number(gp.latitude);
          const lon = Number(gp.longitude);
          if (!Number.isFinite(lat) || !Number.isFinite(lon)) return false;
          // Coarse bounding box first
          if (lat < latMin || lat > latMax || lon < lonMin || lon > lonMax) return false;
          // Then precise distance
          const dist = haversineMiles(latitude, longitude, lat, lon);
          const deviceRadius = Math.min(
            Math.max(Number(data.radiusMiles ?? radiusMiles), 0.1),
            MAX_NEARBY_RADIUS_MILES,
          );
          return dist <= deviceRadius;
        })
        .slice(0, MAX_FANOUT_PER_SIGHTING);

      const tokens = Array.from(
        new Set(
          candidates
            .map(({data}) => (data.token ?? "").toString().trim())
            .filter((t) => t.length > 0),
        ),
      );

      if (tokens.length > 0) {
        const title = isEnforcer ? "Nearby enforcement" : "Nearby tow";
        const bodyBase = notes
          ? notes.toString().slice(0, 180)
          : `Report near ${location}`;
        const body = `${bodyBase} (within ~${radiusMiles} miles)`;

        let totalSuccess = 0;
        let totalFailure = 0;
        const invalidTokens = new Set<string>();

        for (const part of chunk(tokens, MULTICAST_CHUNK_SIZE)) {
          const multicast = await admin.messaging().sendEachForMulticast({
            tokens: part,
            notification: {title, body},
            data: {
              kind: "nearby_sighting",
              alertId: alertRef.id,
              type: isEnforcer ? "enforcer" : "tow",
            },
          });

          totalSuccess += multicast.successCount;
          totalFailure += multicast.failureCount;

          multicast.responses.forEach((r, i) => {
            if (r.success) return;
            const code = (r.error as any)?.code ?? "";
            if (
              code === "messaging/registration-token-not-registered" ||
              code === "messaging/invalid-registration-token"
            ) {
              invalidTokens.add(part[i]);
            }
          });
        }

        logger.info("submitSighting fanout complete", {
          alertId: alertRef.id,
          reporterUid,
          tokens: tokens.length,
          successCount: totalSuccess,
          failureCount: totalFailure,
          geohashPrefixLen: precision,
        });

        if (invalidTokens.size > 0) {
          const snap = await devicesRef
            .where("token", "in", Array.from(invalidTokens).slice(0, 10))
            .get()
            .catch(() => null);
          if (snap) {
            const batch = db.batch();
            snap.docs.forEach((d) => batch.delete(d.ref));
            await batch.commit().catch(() => {});
          }
        }
      }
    } catch (e) {
      logger.warn("submitSighting fanout failed", {
        alertId: alertRef.id,
        err: (e as any)?.message ?? String(e),
      });
    }
  }

  const userMessage = hasGeo && approvalTier !== "manual"
    ? "Report submitted. Nearby drivers will be warned."
    : (approvalTier === "manual"
      ? "Report submitted. It needs review before posting."
      : "Report submitted. It will post shortly if unflagged.");

  return {success: true, message: userMessage};
});

// Helper for development/testing: simulate a nearby warning push without creating an alert.
// Admin-only to prevent abuse.
export const simulateNearbyWarning = onCall(
  {
    secrets: [firebaseAdminSdkKey],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const isAdmin = (request.auth.token as any)?.admin === true || (request.auth.token as any)?.moderator === true;
    if (!isAdmin) {
      throw new HttpsError("permission-denied", "Admin required.");
    }

    const latitude = Number(request.data?.latitude);
    const longitude = Number(request.data?.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      throw new HttpsError("invalid-argument", "latitude/longitude required");
    }
    const radiusMiles = Math.min(
      Math.max(Number(request.data?.radiusMiles ?? DEFAULT_NEARBY_RADIUS_MILES), 0.1),
    MAX_NEARBY_RADIUS_MILES,
  );
  const title = (request.data?.title ?? "Test nearby warning").toString();
  const bodyBase = (request.data?.body ?? "This is a test warning.").toString();
  const body = `${bodyBase} (within ~${radiusMiles} miles)`;

  const db = getFirestore();
  const devicesRef = db.collection("devices");

  const precision = geohashPrecisionForRadiusMiles(radiusMiles);
  const centerHash = encodeGeohash(latitude, longitude, 8);
  const ranges = geohashQueryRanges(centerHash, precision);

  const {latDelta} = approxBoundingBoxDegrees(radiusMiles);
  const latMin = latitude - latDelta;
  const latMax = latitude + latDelta;
  const cosLat = Math.max(0.2, Math.cos((latitude * Math.PI) / 180));
  const lonDelta = radiusMiles / (69 * cosLat);
  const lonMin = longitude - lonDelta;
  const lonMax = longitude + lonDelta;

  const candidateDocs: Array<any> = [];
  for (const r of ranges) {
    const snap = await devicesRef
      .where("geohash", ">=", r.start)
      .where("geohash", "<=", r.end)
      .limit(MAX_CANDIDATE_SCAN)
      .get();
    snap.docs.forEach((d) => candidateDocs.push(d.data()));
  }

  const tokens = Array.from(
    new Set(
      candidateDocs
        .filter((data) => {
          const gp = data.location as GeoPoint | undefined;
          if (!gp) return false;
          const lat = Number(gp.latitude);
          const lon = Number(gp.longitude);
          if (!Number.isFinite(lat) || !Number.isFinite(lon)) return false;
          if (lat < latMin || lat > latMax || lon < lonMin || lon > lonMax) return false;
          const dist = haversineMiles(latitude, longitude, lat, lon);
          const deviceRadius = Math.min(
            Math.max(Number(data.radiusMiles ?? radiusMiles), 0.1),
            MAX_NEARBY_RADIUS_MILES,
          );
          return dist <= deviceRadius;
        })
        .map((data) => (data.token ?? "").toString().trim())
        .filter((t) => t.length > 0),
    ),
  ).slice(0, MAX_FANOUT_PER_SIGHTING);

  // FALLBACK: If no nearby devices found, send to the caller's own devices for testing
  if (tokens.length === 0) {
    const callerDevices = await devicesRef
      .where("uid", "==", request.auth.uid)
      .limit(5)
      .get();
    callerDevices.docs.forEach((d) => {
      const data = d.data();
      const t = (data.token ?? "").toString().trim();
      if (t.length > 0) tokens.push(t);
    });
    logger.info("simulateNearbyWarning: No nearby devices, falling back to caller devices", {
      callerUid: request.auth.uid,
      callerDeviceCount: tokens.length,
    });
  }

  let totalSuccess = 0;
  let totalFailure = 0;
  
  if (tokens.length > 0) {
    // Use direct HTTP API for FCM (same as testPushToSelf)
    const {GoogleAuth} = await import("google-auth-library");
    const secretValue = firebaseAdminSdkKey.value();
    const serviceAccountKey = JSON.parse(secretValue);
    
    const auth = new GoogleAuth({
      credentials: serviceAccountKey,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const accessToken = await auth.getAccessToken();

    for (const token of tokens) {
      try {
        const fcmResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccountKey.project_id}/messages:send`,
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token,
                notification: {title, body},
                data: {kind: "test_nearby"},
              },
            }),
          }
        );
        if (fcmResponse.ok) {
          totalSuccess++;
        } else {
          totalFailure++;
          const errBody = await fcmResponse.text();
          logger.warn("simulateNearbyWarning FCM error", {token: token.slice(0, 10), error: errBody});
        }
      } catch (err) {
        totalFailure++;
        logger.error("simulateNearbyWarning send error", {error: String(err)});
      }
    }
  }

  return {success: true, tokens: tokens.length, successCount: totalSuccess, failureCount: totalFailure};
});


// Server-driven tier processing for alerts that may be created by other paths.
// Ensures fields are consistent even if something writes into /alerts directly.
export const applyApprovalTierOnAlertCreate = onDocumentCreated(
  "alerts/{alertId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = (snap.data() as any) ?? {};
    // If the document already has approvalTier, we assume it was created by backend logic.
    if (data.approvalTier) return;

    const reporterUid = (data.reporterUid ?? "unknown").toString();
    const notes = (data.message ?? data.notes ?? "").toString();
    const gp = data.geo as GeoPoint | null | undefined;
    const hasGeo = Boolean(gp && Number.isFinite(gp.latitude) && Number.isFinite(gp.longitude));

    const decision = determineApprovalTier({
      reporterUid,
      notes,
      hasGeo,
    });
    const tier: ApprovalTier = decision.tier;
    const status: AlertStatus = tier === "auto" ? "active" : "pending";

    await snap.ref.set(
      {
        approvalTier: tier,
        reviewReason: decision.reviewReason ?? null,
        status,
        active: status === "active",
        flagged: false,
        softApproveAfter: tier === "soft"
          ? Timestamp.fromMillis(Date.now() + SOFT_AUTO_APPROVE_DELAY_MINUTES * 60 * 1000)
          : null,
      },
      {merge: true},
    );
  },
);

export const autoApproveSoftAlerts = onSchedule("every 5 minutes", async () => {
  const db = getFirestore();
  const now = Timestamp.now();

  const snap = await db
    .collection("alerts")
    .where("approvalTier", "==", "soft")
    .where("status", "==", "pending")
    .where("softApproveAfter", "<=", now)
    .limit(250)
    .get();

  if (snap.empty) return;

  const batch = db.batch();
  snap.docs.forEach((d) => {
    const data = d.data() as any;
    if (data.flagged === true) return;
    batch.set(
      d.ref,
      {
        status: "active",
        active: true,
        autoApprovedAt: now,
      },
      {merge: true},
    );
  });

  await batch.commit();
});

export const registerDevice = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const data = (request.data ?? {}) as RegisterDeviceRequest;
  const token = (data.token ?? "").toString().trim();
  if (!token) {
    throw new HttpsError("invalid-argument", "FCM token required.");
  }
  const platform =
    ((data.platform ?? "unknown").toString().toLowerCase() as DevicePlatform) ||
    "unknown";
  const latitude = Number(data.latitude);
  const longitude = Number(data.longitude);
  const hasGeo = Number.isFinite(latitude) && Number.isFinite(longitude);
  const radiusRaw = Number(data.radiusMiles ?? DEFAULT_NEARBY_RADIUS_MILES);
  const radiusMiles = Math.min(
    Math.max(Number.isFinite(radiusRaw) ? radiusRaw : DEFAULT_NEARBY_RADIUS_MILES, 0.1),
    MAX_NEARBY_RADIUS_MILES,
  );
  const precisionRaw = Number(data.locationPrecisionMeters);
  const precision = Number.isFinite(precisionRaw) ? precisionRaw : null;

  try {
    const db = getFirestore();
    const now = Timestamp.now();

    // One device record per token; users may reinstall so uid can change.
    const docId = token.replace(/[^A-Za-z0-9_.-]/g, "_").slice(0, 200);
    const ref = db.collection("devices").doc(docId);

    const payload: Partial<DeviceDoc> = {
      uid: request.auth.uid,
      token,
      platform,
      radiusMiles,
      locationPrecisionMeters: precision,
      updatedAt: now,
      lastSeenAt: now,
    };
    if (hasGeo) {
      payload.location = new GeoPoint(latitude, longitude);
      payload.geohash = encodeGeohash(latitude, longitude, 8);
    }

    await ref.set(
      {
        ...payload,
        createdAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
    );

    return {success: true};
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    logger.error("registerDevice failed", {
      uid: request.auth.uid,
      tokenPrefix: token.slice(0, 10),
      platform,
      hasGeo,
      latitude,
      longitude,
      radiusMiles,
      locationPrecisionMeters: precision,
      message,
      stack: err instanceof Error ? err.stack : undefined,
    });
    throw new HttpsError("internal", "registerDevice failed", {
      message,
    });
  }
});

export const approveAlert = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  // Only admins/moderators can approve.
  const isAdmin = (request.auth.token as any)?.admin === true || (request.auth.token as any)?.moderator === true;
  if (!isAdmin) {
    throw new HttpsError("permission-denied", "Admin approval required.");
  }
  const alertId = (request.data?.alertId ?? "").toString().trim();
  if (!alertId) {
    throw new HttpsError("invalid-argument", "alertId required");
  }

  const db = getFirestore();
  const ref = db.collection("alerts").doc(alertId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Alert not found");
  }

  const now = Timestamp.now();
  await ref.set(
    {
      status: "active",
      active: true,
      approvedAt: now,
      approvedBy: request.auth.uid,
    },
    {merge: true},
  );

  return {success: true};
});

export const unregisterDevice = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const token = (request.data?.token ?? "").toString().trim();
  if (!token) {
    throw new HttpsError("invalid-argument", "FCM token required.");
  }
  const docId = token.replace(/[^A-Za-z0-9_.-]/g, "_").slice(0, 200);
  await getFirestore().collection("devices").doc(docId).delete().catch(() => {});
  return {success: true};
});

// Run with firebase-adminsdk service account for FCM permissions
// Uses secret to get explicit credentials and raw HTTP for FCM
export const testPushToSelf = onCall(
  {
    serviceAccount: "firebase-adminsdk-fbsvc@mkeparkapp-1ad15.iam.gserviceaccount.com",
    secrets: [firebaseAdminSdkKey],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const token = (request.data?.token ?? "").toString().trim();
    if (!token) {
      throw new HttpsError("invalid-argument", "FCM token required.");
    }

    const title = (request.data?.title ?? "CitySmart test").toString();
    const body = (request.data?.body ?? "Test notification").toString();

    try {
      // Use google-auth-library to get access token directly
      const {GoogleAuth} = await import("google-auth-library");
      
      const secretValue = firebaseAdminSdkKey.value();
      logger.info("Secret loaded", {secretLength: secretValue?.length ?? 0});
      
      const serviceAccountKey = JSON.parse(secretValue);
      logger.info("Parsed service account key", {
        projectId: serviceAccountKey.project_id,
        clientEmail: serviceAccountKey.client_email,
      });

      // Create auth client with explicit credentials
      const auth = new GoogleAuth({
        credentials: serviceAccountKey,
        scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
      });

      const accessToken = await auth.getAccessToken();
      logger.info("Got access token", {tokenLength: accessToken?.length ?? 0});

      // Send FCM message via HTTP API
      const fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccountKey.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {title, body},
              data: {kind: "test"},
            },
          }),
        }
      );

      const fcmResult = await fcmResponse.json();
      logger.info("FCM response", {status: fcmResponse.status, result: fcmResult});

      if (!fcmResponse.ok) {
        throw new Error(`FCM error: ${JSON.stringify(fcmResult)}`);
      }

      return {success: true, messageId: fcmResult.name};
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      logger.error("testPushToSelf failed", {
        uid: request.auth.uid,
        tokenPrefix: token.slice(0, 10),
        title,
        body,
        message,
        stack: err instanceof Error ? err.stack : undefined,
      });
      throw new HttpsError("internal", "testPushToSelf failed", {
        message,
      });
    }
  }
);

export const notifyOnApproval = onDocumentWritten(
  "alerts/{alertId}",
  async (event) => {
    const after = event.data?.after;
    if (!after || !after.exists) return;

    const data = after.data() as any;
    const isActive = data.active === true || data.status === "active";

    if (isActive) {
      const title = (data.title ?? "Alert").toString();
      const message = (data.message ?? "").toString();
      const location = (data.location ?? "").toString();
      const body = [message, location ? `at ${location}` : ""]
        .filter((part) => part && part.trim().length > 0)
        .join(" ");

      try {
        await admin.messaging().send({
          topic: "alerts",
          notification: {
            title,
            body: body || "New alert.",
          },
        });
        logger.info("notifyOnApproval sent topic notification", {
          alertId: event.params.alertId,
          title,
        });
      } catch (err) {
        // Log but don't throw - we don't want to retry document triggers for FCM failures
        logger.error("notifyOnApproval FCM failed", {
          alertId: event.params.alertId,
          error: err instanceof Error ? err.message : String(err),
        });
      }
    }
  },
);

export const sendNearbyAlerts = onCall(async (request) => {
  const radiusMiles = Number(request.data?.radiusMiles ?? 3);
  // production: require auth and coordinates
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }

  const latitude = Number(request.data?.latitude);
  const longitude = Number(request.data?.longitude);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw new HttpsError('invalid-argument', 'Latitude/longitude required.');
  }

  const token = (request.data?.token ?? '').toString().trim();
  if (!token) {
    throw new HttpsError('invalid-argument', 'FCM token required.');
  }
  const windowMinutes = Number(request.data?.windowMinutes ?? 180);
  const limit = Math.min(Number(request.data?.limit ?? 25), 50);

  const now = Date.now();
  const since = Timestamp.fromMillis(
    now - windowMinutes * 60 * 1000,
  );

  const snap = await getFirestore()
    .collection("alerts")
    .where("status", "==", "active")
    .where("createdAt", ">=", since)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  const haversineMiles = (
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ) => {
    const toRad = (deg: number) => (deg * Math.PI) / 180;
    const r = 3958.8;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return r * c;
  };

  const matches = snap.docs
    .map((doc) => ({id: doc.id, data: doc.data()}))
    .filter(({data}) => {
      const geo = data.geo as GeoPoint | undefined;
      const lat = Number(geo?.latitude ?? data.latitude);
      const lng = Number(geo?.longitude ?? data.longitude);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
      const dist = haversineMiles(latitude, longitude, lat, lng);
      return dist <= radiusMiles;
    });

  const sendLimit = Math.min(matches.length, 5);
  let successCount = 0;
  let failureCount = 0;
  
  for (let i = 0; i < sendLimit; i++) {
    const match = matches[i];
    const title = (match.data.title ?? "Alert").toString();
    const message = (match.data.message ?? "").toString();
    const location = (match.data.location ?? "").toString();
    const body = [message, location ? `at ${location}` : ""]
      .filter((part) => part && part.trim().length > 0)
      .join(" ");

    try {
      await admin.messaging().send({
        token,
        notification: {
          title,
          body: body || "Nearby alert.",
        },
        data: {
          alertId: match.id,
          type: (match.data.type ?? "").toString(),
        },
      });
      successCount++;
    } catch (err) {
      failureCount++;
      const errMsg = err instanceof Error ? err.message : String(err);
      logger.warn("sendNearbyAlerts FCM send failed", {
        alertId: match.id,
        tokenPrefix: token.slice(0, 10),
        error: errMsg,
      });
      // If token is invalid, break early - no point sending more
      if (errMsg.includes("not-registered") || errMsg.includes("invalid")) {
        break;
      }
    }
  }

  return {
    success: true,
    sent: successCount,
    failed: failureCount,
    totalMatches: matches.length,
  };
});
