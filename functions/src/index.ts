import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

admin.initializeApp();
import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

export const helloWorld = onRequest((req, res) => {
  logger.info("helloWorld hit", {method: req.method, path: req.path});
  res.status(200).send("Hello from Firebase Functions!");
});
export const cleanupExpiredSightings = onSchedule("every 5 minutes", async () => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

const queries = [
  db.collectionGroup("sightings") // catches /sightings and any users/*/sightings
    .where("status", "==", "active")
    .where("expiresAt", "<=", now),

  db.collection("live_sightings") // catches top-level /live_sightings
    .where("status", "==", "active")
    .where("expiresAt", "<=", now),
];

const snaps = await Promise.all(queries.map(q => q.get()));

let total = 0;
const batch = db.batch();

for (const snap of snaps) {
  snap.docs.forEach(doc => {
    total++;
    batch.update(doc.ref, {
      status: "expired",
      expiredAt: now,
    });
  });
}

if (total === 0) return;

await batch.commit();
