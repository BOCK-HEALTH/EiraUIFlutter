// backend/api/auth.js
// --- TEMPORARY DEBUGGING CODE ---
// This file will help us see what the Vercel server is actually reading.

module.exports = async (req, res) => {
  try {
    // We are not verifying any tokens in this test.
    // We are only reading the environment variables.

    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;

    // Log the values on the server side (for Vercel logs)
    console.log("--- DEBUGGING VERCEL ENV VARS ---");
    console.log("Project ID seen by server:", projectId);
    console.log("Client Email seen by server:", clientEmail);
    // Log only the start and end of the key to check its format
    console.log("Private Key starts with:", privateKey ? privateKey.substring(0, 30) : "UNDEFINED");
    console.log("Private Key ends with:", privateKey ? privateKey.slice(-30) : "UNDEFINED");
    console.log("Does Private Key include '\\n'?:", privateKey ? privateKey.includes('\\n') : "N/A");
    console.log("------------------------------------");

    // Send the values back to the Flutter app so we can see them immediately.
    return res.status(418).json({ // Using an unused status code to indicate this is a debug response
      message: "This is a debug response. Check the data.",
      env: {
        projectId: projectId || "Project ID is UNDEFINED",
        clientEmail: clientEmail || "Client Email is UNDEFINED",
        privateKey: privateKey || "Private Key is UNDEFINED",
      }
    });

  } catch (error) {
    // If even reading the variables fails, this will catch it.
    return res.status(500).json({ error: "A critical error occurred while reading env vars.", details: error.message });
  }
};