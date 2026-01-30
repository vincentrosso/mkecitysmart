#!/usr/bin/env node
/**
 * Set admin custom claim on a user.
 * 
 * Usage:
 *   node set_admin_claim.js <uid>
 *   node set_admin_claim.js 6F33F8XhBUe9C9YW3lu7DA980282
 * 
 * After running, the user must sign out and sign back in to pick up the new claim.
 */

const admin = require("firebase-admin");

// Initialize with application default credentials
admin.initializeApp({
  projectId: "mkeparkapp-1ad15",
});

async function setAdminClaim(uid) {
  if (!uid) {
    console.error("Usage: node set_admin_claim.js <uid>");
    process.exit(1);
  }

  try {
    // Get current user
    const user = await admin.auth().getUser(uid);
    console.log(`Found user: ${user.email || user.uid}`);
    console.log(`Current claims: ${JSON.stringify(user.customClaims || {})}`);

    // Set admin claim
    await admin.auth().setCustomUserClaims(uid, {
      ...user.customClaims,
      admin: true,
    });

    // Verify
    const updated = await admin.auth().getUser(uid);
    console.log(`Updated claims: ${JSON.stringify(updated.customClaims || {})}`);
    console.log("\n✅ Admin claim set successfully!");
    console.log("ℹ️  User must sign out and sign back in to pick up the new claim.");
  } catch (error) {
    console.error("Error setting admin claim:", error.message);
    process.exit(1);
  }
}

const uid = process.argv[2];
setAdminClaim(uid).then(() => process.exit(0));
