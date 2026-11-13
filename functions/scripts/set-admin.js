const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");

const email = process.argv[2];
if (!email) {
  console.error("Usage: node scripts/set-admin.js <account-email>");
  process.exitCode = 1;
} else {
  initializeApp();
  getAuth()
    .getUserByEmail(email)
    .then((user) => getAuth().setCustomUserClaims(user.uid, {admin: true}))
    .then(() => console.log(`Admin claim granted to ${email}`))
    .catch((error) => {
      console.error("Could not grant admin claim:", error.message);
      process.exitCode = 1;
    });
}
