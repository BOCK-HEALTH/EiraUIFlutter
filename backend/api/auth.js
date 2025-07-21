const { verifyToken } = require("../lib/firebase-admin")
const { getPool } = require("../lib/db")

module.exports = async (req, res) => {
  const pool = getPool()
  const url = req.url.replace("/api/auth", "").replace("/auth", "")

  try {
    if (url === "/verify" && req.method === "POST") {
      const { idToken } = req.body

      if (!idToken) {
        return res.status(400).json({ error: "ID token is required" })
      }

      const decodedToken = await verifyToken(idToken)

      // Get or create user in database
      const result = await pool.query(
        `INSERT INTO users (email, name, firebase_uid)
         VALUES ($1, $2, $3)
         ON CONFLICT (email) DO UPDATE SET 
         firebase_uid = EXCLUDED.firebase_uid,
         name = CASE 
           WHEN users.name IS NULL OR users.name = '' THEN EXCLUDED.name
           ELSE users.name
         END
         RETURNING *`,
        [decodedToken.email, decodedToken.name || decodedToken.email?.split("@")[0] || "User", decodedToken.uid],
      )

      return res.json({
        success: true,
        user: {
          uid: decodedToken.uid,
          email: decodedToken.email,
          displayName: decodedToken.name || result.rows[0]?.name,
        },
        dbUser: result.rows[0],
      })
    }

    return res.status(404).json({ error: "Auth route not found" })
  } catch (error) {
    console.error("Auth error:", error)
    return res.status(500).json({ error: error.message || "Authentication failed" })
  }
}
