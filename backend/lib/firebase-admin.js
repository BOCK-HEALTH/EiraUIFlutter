const admin = require("firebase-admin")

let app

function getFirebaseAdmin() {
  if (!app) {
    const serviceAccount = {
      type: "service_account",
      project_id: process.env.FIREBASE_PROJECT_ID,
      private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
      client_email: process.env.FIREBASE_CLIENT_EMAIL,
    }

    app = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    })
  }
  return app
}

async function verifyToken(idToken) {
  try {
    const app = getFirebaseAdmin()
    const decodedToken = await app.auth().verifyIdToken(idToken)
    return decodedToken
  } catch (error) {
    throw new Error("Invalid token")
  }
}

module.exports = { getFirebaseAdmin, verifyToken }
