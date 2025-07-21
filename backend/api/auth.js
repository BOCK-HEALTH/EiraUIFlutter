const admin = require('../lib/firebase-admin');

module.exports = async (req, res) => {
  // This file is currently only for verifying, which is a POST request.
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { idToken } = req.body;
  if (!idToken) {
    return res.status(400).json({ error: 'ID token is required.' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    res.status(200).json({ status: 'success', uid: decodedToken.uid, email: decodedToken.email });
  } catch (error) {
    console.error('Error verifying token:', error);
    res.status(401).json({ error: 'Unauthorized: Invalid token' });
  }
};