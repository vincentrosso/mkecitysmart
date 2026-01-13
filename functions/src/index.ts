import {onDocumentCreated, onDocumentWritten} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

export const mirrorUserSightingToGlobal = onDocumentCreated(
  "users/{uid}/sightings/{sightingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const uid = event.params.uid as string;
    const sightingId = event.params.sightingId as string;

    const data = snap.data() as any;
    const db = admin.firestore();

    const now = admin.firestore.Timestamp.now();
    const merged = {
      ...data,
      uid: data?.uid ?? uid,
      status: data?.status ?? "active",
      createdAt: data?.createdAt ?? now,
      expiresAt:
        data?.expiresAt ??
        admin.firestore.Timestamp.fromMillis(now.toMillis() + 2 * 60 * 60 * 1000),
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
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

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
    const db = admin.firestore();
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

    const now = admin.firestore.Timestamp.now();
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
      mirroredAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("alerts").doc(sightingId).set(alertDoc, {merge: true});
  },
);
