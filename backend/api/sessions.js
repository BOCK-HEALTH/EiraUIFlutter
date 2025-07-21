// backend/api/sessions.js
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
        const { rows } = await db.query('SELECT id, title, created_at FROM chat_sessions WHERE user_email = $1 ORDER BY created_at DESC', [email]);
        return res.status(200).json(rows);

      case 'POST':
        const { title } = req.body;
        if (!title) return res.status(400).json({ error: 'Title is required' });
        const insertResult = await db.query('INSERT INTO chat_sessions (user_email, title) VALUES ($1, $2) RETURNING id, title, created_at', [email, title]);
        return res.status(200).json(insertResult.rows[0]);

      case 'PUT':
        const { sessionId, newTitle } = req.body;
        if (!sessionId || !newTitle) return res.status(400).json({ error: 'sessionId and newTitle are required' });
        const updateResult = await db.query('UPDATE chat_sessions SET title = $1 WHERE id = $2 AND user_email = $3', [newTitle, sessionId, email]);
        if (updateResult.rowCount === 0) return res.status(404).json({ error: 'Session not found or not owned by user' });
        return res.status(200).json({ status: 'success' });

      case 'DELETE':
        const { sessionId: idToDelete } = req.query;
        if (!idToDelete) return res.status(400).json({ error: 'sessionId query parameter is required for deletion' });
        
        await db.query('DELETE FROM chat_history WHERE session_id = $1', [idToDelete]);
        await db.query('DELETE FROM chat_sessions WHERE id = $1 AND user_email = $2', [idToDelete, email]);
        return res.status(200).json({ status: 'success' });

      default:
        res.setHeader('Allow', ['GET', 'POST', 'PUT', 'DELETE']);
        return res.status(405).end(`Method ${req.method} Not Allowed`);
    }
  } catch (error) {
    console.error('Sessions API Error:', error.message);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};