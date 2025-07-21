const cors = require("cors")

// CORS configuration
const corsOptions = {
  origin: true, // Allow all origins for mobile app
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
}

module.exports = async (req, res) => {
  // Apply CORS
  await new Promise((resolve, reject) => {
    cors(corsOptions)(req, res, (result) => {
      if (result instanceof Error) {
        return reject(result)
      }
      return resolve(result)
    })
  })

  // Handle preflight requests
  if (req.method === "OPTIONS") {
    return res.status(200).end()
  }

  // Health check
  if (req.url === "/health" || req.url === "/api/health") {
    return res.json({ status: "OK", message: "Server is running" })
  }

  // Route to appropriate handler
  const url = req.url.replace("/api", "")

  if (url.startsWith("/auth")) {
    const authHandler = require("./auth")
    return authHandler(req, res)
  } else if (url.startsWith("/chat")) {
    const chatHandler = require("./chat")
    return chatHandler(req, res)
  } else if (url.startsWith("/sessions")) {
    const sessionsHandler = require("./sessions")
    return sessionsHandler(req, res)
  } else if (url.startsWith("/users")) {
    const usersHandler = require("./users")
    return usersHandler(req, res)
  }

  return res.status(404).json({ error: "Route not found" })
}
