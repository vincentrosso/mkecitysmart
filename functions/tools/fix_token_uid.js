const admin = require("firebase-admin");
admin.initializeApp({ projectId: "mkeparkapp-1ad15" });
const db = admin.firestore();

const yourUid = "6F33F8XhBUe9C9YW3lu7DA980282";

(async () => {
  try {
    // Find the new token and fix its UID
    const snap = await db.collection("devices").get();
    
    for (const doc of snap.docs) {
      const d = doc.data();
      const token = d.token || "";
      if (token.endsWith("494s")) {
        console.log("Found token, updating UID...");
        console.log("   Old UID:", d.uid);
        console.log("   New UID:", yourUid);
        await doc.ref.update({ uid: yourUid });
        console.log("✅ Token UID updated!");
      }
    }
    
    // Delete all old tokens for your UID except the new one
    const yourDevices = await db.collection("devices").where("uid", "==", yourUid).get();
    console.log("\n📱 Devices for your UID after update:", yourDevices.size);
    
    for (const doc of yourDevices.docs) {
      const token = doc.data().token || "";
      if (token.endsWith("494s")) {
        console.log("   ✓ KEEP (current):", token.slice(0, 15) + "...");
      } else {
        console.log("   ✗ DELETE (stale):", token.slice(0, 15) + "...");
        await doc.ref.delete();
      }
    }
    
    console.log("\n🎉 Done! Try Simulate nearby now.");
    process.exit(0);
  } catch (e) {
    console.error("Error:", e);
    process.exit(1);
  }
})();
