// backend/api/users.js
const admin = require('../lib/firebase-admin');
const db = require('../lib/db');

module.exports = async (req, res) => {
  try {
    const idToken = req.headers.authorization?.split('Bearer ')[1];
    if (!idToken) return res.status(401).json({ error: 'Unauthorized' });
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const { email, name: firebaseName } = decodedToken;

    switch (req.method) {
      case 'GET': // Get user info
        const { rows } = await db.query('SELECT email, name FROM users WHERE email = $1', [email]);
        if (rows.length === 0) return res.status(404).json({ error: 'User not found' });
        return res.status(200).json(rows[0]);

      case 'POST': // Get or Create user
        const displayName = req.body.name || firebaseName || 'New User';
        let userResult = await db.query('SELECT email, name FROM users WHERE email = $1', [email]);
        if (userResult.rows.length === 0) {
          const insertResult = await db.query('INSERT INTO users (email, name) VALUES ($1, $2) RETURNING email, name', [email, displayName]);
          userResult = insertResult;
        }
        return res.status(200).json(userResult.rows[0]);

      default:
        res.setHeader('Allow', ['GET', 'POST']);
        return res.status(405).end(`Method ${req.method} Not Allowed`);
    }
  } catch (error) {
    console.error('User API Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};