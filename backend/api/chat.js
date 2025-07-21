const { verifyToken } = require("../lib/firebase-admin")
const { getPool } = require("../lib/db")

module.exports = async (req, res) => {
  const pool = getPool()
  const url = req.url.replace("/api/chat", "").replace("/chat", "")

  try {
    // Verify authentication
    const authHeader = req.headers.authorization
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Authorization token required" })
    }

    const idToken = authHeader.split("Bearer ")[1]
    const decodedToken = await verifyToken(idToken)

    if (url === "/add" && req.method === "POST") {
      const { session_id, message, sender } = req.body

      if (!session_id || !message || !sender) {
        return res.status(400).json({ error: "session_id, message, and sender are required" })
      }

      await pool.query(
        `INSERT INTO chat_history (user_email, session_id, message, sender)
         VALUES ($1, $2, $3, $4)`,
        [decodedToken.email, session_id, message, sender],
      )

      return res.json({ success: true })
    }

    if (url === "/history" && req.method === "GET") {
      const { session_id } = req.query

      if (!session_id) {
        return res.status(400).json({ error: "session_id is required" })
      }

      const result = await pool.query(
        `SELECT message, sender, created_at
         FROM chat_history
         WHERE session_id = $1 AND user_email = $2
         ORDER BY created_at ASC`,
        [session_id, decodedToken.email],
      )

      return res.json(result.rows)
    }

    return res.status(404).json({ error: "Chat route not found" })
  } catch (error) {
    console.error("Chat error:", error)
    return res.status(500).json({ error: error.message || "Chat operation failed" })
  }
}
