// backend/api/chat.js
const { verifyToken } = require('../lib/firebase-admin'); // Import the new verifyToken function
const db = require('../lib/db');

module.exports = async (req, res) => {
  try {
    const idToken = req.headers.authorization?.split('Bearer ')[1];
    if (!idToken) return res.status(401).json({ error: 'Unauthorized' });
    const decodedToken = await verifyToken(idToken); // Use the helper
    const { email } = decodedToken;

    switch (req.method) {
      case 'GET':
        const { session_id } = req.query;
        if (!session_id) return res.status(400).json({ error: 'session_id is required' });

        const historyQuery = `
          SELECT h.id, h.session_id, h.message, h.sender, h.created_at FROM chat_history h
          JOIN chat_sessions s ON h.session_id = s.id
          WHERE h.session_id = $1 AND s.user_email = $2 ORDER BY h.created_at ASC`;
        const { rows } = await db.query(historyQuery, [session_id, email]);
        return res.status(200).json(rows);

      case 'POST':
        const { session_id: newMsgSessionId, message, sender } = req.body;
        if (!newMsgSessionId || !message || !sender) return res.status(400).json({ error: 'session_id, message, and sender are required' });
        
        const addMsgQuery = 'INSERT INTO chat_history (session_id, user_email, sender, message) VALUES ($1, $2, $3, $4)';
        await db.query(addMsgQuery, [newMsgSessionId, email, sender, message]);
        return res.status(200).json({ status: 'success' });

      default:
        res.setHeader('Allow', ['GET', 'POST']);
        return res.status(405).end(`Method ${req.method} Not Allowed`);
    }
  } catch (error) {
    console.error('Chat API Error:', error.message);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};