const { verifyToken } = require("../lib/firebase-admin")
const { getPool } = require("../lib/db")

module.exports = async (req, res) => {
  const pool = getPool()
  const url = req.url.replace("/api/sessions", "").replace("/sessions", "")

  try {
    // Verify authentication
    const authHeader = req.headers.authorization
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Authorization token required" })
    }

    const idToken = authHeader.split("Bearer ")[1]
    const decodedToken = await verifyToken(idToken)

    if (url === "/create" && req.method === "POST") {
      const { title } = req.body

      const result = await pool.query(`INSERT INTO chat_sessions (user_email, title) VALUES ($1, $2) RETURNING *`, [
        decodedToken.email,
        title || "Untitled Session",
      ])

      return res.json(result.rows[0])
    }

    if (url === "/list" && req.method === "GET") {
      const result = await pool.query(
        `SELECT id, title, created_at FROM chat_sessions 
         WHERE user_email = $1 ORDER BY created_at DESC`,
        [decodedToken.email],
      )

      return res.json(result.rows)
    }

    if (url === "/rename" && req.method === "PUT") {
      const { sessionId, newTitle } = req.body

      if (!sessionId || !newTitle) {
        return res.status(400).json({ error: "sessionId and newTitle are required" })
      }

      await pool.query(`UPDATE chat_sessions SET title = $1 WHERE id = $2 AND user_email = $3`, [
        newTitle,
        sessionId,
        decodedToken.email,
      ])

      return res.json({ success: true })
    }

    if (url.startsWith("/") && req.method === "DELETE") {
      const sessionId = url.substring(1) // Remove leading slash

      if (!sessionId) {
        return res.status(400).json({ error: "Session ID is required" })
      }

      await pool.query(`DELETE FROM chat_sessions WHERE id = $1 AND user_email = $2`, [sessionId, decodedToken.email])

      return res.json({ success: true })
    }

    return res.status(404).json({ error: "Sessions route not found" })
  } catch (error) {
    console.error("Sessions error:", error)
    return res.status(500).json({ error: error.message || "Sessions operation failed" })
  }
}
