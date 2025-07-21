// backend/api/auth.js
const { verifyToken } = require('../lib/firebase-admin'); // Import the new verifyToken function

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { idToken } = req.body;
  if (!idToken) {
    return res.status(400).json({ error: 'ID token is required.' });
  }

  try {
    // Use the new helper function to verify the token
    const decodedToken = await verifyToken(idToken);
    res.status(200).json({ status: 'success', uid: decodedToken.uid, email: decodedToken.email });
  } catch (error) {
    console.error('Auth API Error:', error.message);
    // The helper throws "Invalid token", so we send a 401
    res.status(401).json({ error: 'Unauthorized: ' + error.message });
  }
};