const { verifyToken } = require("../lib/firebase-admin")
const { getPool } = require("../lib/db")

module.exports = async (req, res) => {
  const pool = getPool()
  const url = req.url.replace("/api/users", "").replace("/users", "")

  try {
    // Verify authentication
    const authHeader = req.headers.authorization
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Authorization token required" })
    }

    const idToken = authHeader.split("Bearer ")[1]
    const decodedToken = await verifyToken(idToken)

    if (url === "/update-name" && req.method === "POST") {
      const { name } = req.body

      if (!name) {
        return res.status(400).json({ error: "Name is required" })
      }

      if (name.trim().length < 1) {
        return res.status(400).json({ error: "Name cannot be empty" })
      }

      if (name.trim().length > 100) {
        return res.status(400).json({ error: "Name is too long (max 100 characters)" })
      }

      const result = await pool.query("UPDATE users SET name = $1 WHERE email = $2 RETURNING *", [
        name.trim(),
        decodedToken.email,
      ])

      if (result.rowCount === 0) {
        return res.status(404).json({ error: "User not found" })
      }

      return res.json({
        success: true,
        message: "Name updated successfully",
        user: result.rows[0],
      })
    }

    if (url === "/get-user" && req.method === "GET") {
      const result = await pool.query("SELECT * FROM users WHERE email = $1", [decodedToken.email])

      if (result.rowCount === 0) {
        return res.status(404).json({ error: "User not found" })
      }

      return res.json(result.rows[0])
    }

    if (url === "/get-or-create" && req.method === "POST") {
      const { name } = req.body

      const result = await pool.query(
        `INSERT INTO users (email, name, firebase_uid)
         VALUES ($1, $2, $3)
         ON CONFLICT (email) DO UPDATE SET 
         name = CASE 
           WHEN users.name IS NULL OR users.name = '' THEN $2
           ELSE users.name
         END,
         firebase_uid = EXCLUDED.firebase_uid
         RETURNING *`,
        [decodedToken.email, name || "User", decodedToken.uid],
      )

      return res.json(result.rows[0])
    }

    return res.status(404).json({ error: "Users route not found" })
  } catch (error) {
    console.error("Users error:", error)
    return res.status(500).json({ error: error.message || "Users operation failed" })
  }
}
