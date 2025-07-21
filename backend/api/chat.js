// backend/api/chat.js
const admin = require('../lib/firebase-admin');
const db = require('../lib/db');

module.exports = async (req, res) => {
  try {
    const idToken = req.headers.authorization?.split('Bearer ')[1];
    if (!idToken) return res.status(401).json({ error: 'Unauthorized' });
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const { email } = decodedToken;

    switch (req.method) {
      case 'GET': // Get chat history for a session
        const { session_id } = req.query;
        if (!session_id) return res.status(400).json({ error: 'session_id is required' });

        const historyQuery = `
          SELECT h.* FROM chat_history h JOIN chat_sessions s ON h.session_id = s.id
          WHERE h.session_id = $1 AND s.user_email = $2 ORDER BY h.created_at ASC`;
        const { rows } = await db.query(historyQuery, [session_id, email]);
        return res.status(200).json(rows);

      case 'POST': // Add a new message
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
    console.error('Chat API Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};