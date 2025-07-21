// backend/api/sessions.js
const admin = require('../lib/firebase-admin');
const db = require('../lib/db');

module.exports = async (req, res) => {
  try {
    const idToken = req.headers.authorization?.split('Bearer ')[1];
    if (!idToken) return res.status(401).json({ error: 'Unauthorized' });
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const { email } = decodedToken;

    switch (req.method) {
      case 'GET': // List all sessions
        const { rows } = await db.query('SELECT id, title, created_at FROM chat_sessions WHERE user_email = $1 ORDER BY created_at DESC', [email]);
        return res.status(200).json(rows);

      case 'POST': // Create a new session
        const { title } = req.body;
        if (!title) return res.status(400).json({ error: 'Title is required' });
        const insertResult = await db.query('INSERT INTO chat_sessions (user_email, title) VALUES ($1, $2) RETURNING id, title, created_at', [email, title]);
        return res.status(200).json(insertResult.rows[0]);

      case 'PUT': // Rename a session
        const { sessionId, newTitle } = req.body;
        if (!sessionId || !newTitle) return res.status(400).json({ error: 'sessionId and newTitle are required' });
        const updateResult = await db.query('UPDATE chat_sessions SET title = $1 WHERE id = $2 AND user_email = $3', [newTitle, sessionId, email]);
        if (updateResult.rowCount === 0) return res.status(404).json({ error: 'Session not found or not owned by user' });
        return res.status(200).json({ status: 'success' });

      case 'DELETE': // Delete a session
        const { sessionId: idToDelete } = req.query; // sessionId from query param
        if (!idToDelete) return res.status(400).json({ error: 'sessionId query parameter is required for deletion' });
        
        // Ensure user owns the session before deleting
        const ownerCheck = await db.query('SELECT id FROM chat_sessions WHERE id = $1 AND user_email = $2', [idToDelete, email]);
        if (ownerCheck.rowCount === 0) return res.status(403).json({ error: 'Forbidden' });

        await db.query('DELETE FROM chat_history WHERE session_id = $1', [idToDelete]);
        await db.query('DELETE FROM chat_sessions WHERE id = $1', [idToDelete]);
        return res.status(200).json({ status: 'success' });

      default:
        res.setHeader('Allow', ['GET', 'POST', 'PUT', 'DELETE']);
        return res.status(405).end(`Method ${req.method} Not Allowed`);
    }
  } catch (error) {
    console.error('Sessions API Error:', error);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
};