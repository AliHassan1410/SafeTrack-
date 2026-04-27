import { OAuth2Client } from "google-auth-library";
import jwt from "jsonwebtoken";
import User from "../models/User.js";

// ✅ Initialize Google OAuth2 Client
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// ─────────────────────────────────────────────────────────────
// 🔐 Helper: Generate JWT
// ─────────────────────────────────────────────────────────────
const generateJWT = (userId) => {
  return jwt.sign(
    { id: userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || "30d" }
  );
};

// ─────────────────────────────────────────────────────────────
// 🔐 Helper: Verify Google ID Token (server-side)
// ─────────────────────────────────────────────────────────────
const verifyGoogleToken = async (idToken) => {
  const ticket = await googleClient.verifyIdToken({
    idToken,
    audience: process.env.GOOGLE_CLIENT_ID,
  });
  return ticket.getPayload(); // { sub, email, name, picture, email_verified, ... }
};

// ─────────────────────────────────────────────────────────────
// POST /api/auth/google
// Body: { idToken, role }
// ─────────────────────────────────────────────────────────────
export const googleSignIn = async (req, res) => {
  try {
    const { idToken, role } = req.body;

    // 1️⃣ Validate input
    if (!idToken) {
      return res.status(400).json({ message: "Google ID token is required" });
    }

    const validRoles = ["reporter", "responder"];
    const userRole = validRoles.includes(role) ? role : "reporter";

    // 2️⃣ Verify Google ID Token with Google's servers
    let googlePayload;
    try {
      googlePayload = await verifyGoogleToken(idToken);
    } catch (err) {
      console.error("Google token verification failed:", err.message);
      return res.status(401).json({ message: "Invalid or expired Google token" });
    }

    const {
      sub: googleId,
      email,
      name,
      picture: profilePic,
      email_verified,
    } = googlePayload;

    // 3️⃣ Email must be verified by Google
    if (!email_verified) {
      return res.status(401).json({ message: "Google email is not verified" });
    }

    // 4️⃣ Check if user already exists (by googleId OR email)
    let user = await User.findOne({
      $or: [{ googleId }, { email: email.toLowerCase() }],
    });

    let isNewUser = false;

    if (user) {
      // ─── Existing user: update Google info if missing ───
      let needsSave = false;

      if (!user.googleId) {
        // User registered with email/password before — link Google account
        user.googleId = googleId;
        user.authProvider = "google";
        needsSave = true;
      }

      if (!user.profilePic && profilePic) {
        user.profilePic = profilePic;
        needsSave = true;
      }

      if (needsSave) {
        await user.save();
      }
    } else {
      // ─── New user: create account ───
      isNewUser = true;

      user = await User.create({
        name: name || email.split("@")[0],
        email: email.toLowerCase(),
        googleId,
        profilePic,
        role: userRole,
        authProvider: "google",
        // password and phone intentionally null for Google users
      });
    }

    // 5️⃣ Generate JWT
    const token = generateJWT(user._id);

    // 6️⃣ Return response
    return res.status(isNewUser ? 201 : 200).json({
      message: isNewUser ? "Account created successfully" : "Logged in successfully",
      isNewUser,
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        responderType: user.responderType || null,
        profilePic: user.profilePic,
        authProvider: user.authProvider,
        googleId: user.googleId,
      },
    });
  } catch (error) {
    console.error("Google Sign-In Error:", error);
    return res.status(500).json({
      message: "Internal server error during Google sign-in",
      error: error.message,
    });
  }
};

// ─────────────────────────────────────────────────────────────
// GET /api/auth/profile   (protected — requires JWT)
// ─────────────────────────────────────────────────────────────
export const getGoogleUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    return res.status(200).json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      responderType: user.responderType || null,
      profilePic: user.profilePic,
      authProvider: user.authProvider,
      phone: user.phone,
      createdAt: user.createdAt,
    });
  } catch (error) {
    console.error("Profile fetch error:", error);
    return res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ─────────────────────────────────────────────────────────────
// POST /api/auth/logout   (optional — client-side token removal)
// ─────────────────────────────────────────────────────────────
export const logout = async (req, res) => {
  // JWTs are stateless; real logout happens on the client by deleting the token.
  // Optionally: add the token to a server-side blacklist (Redis) here.
  return res.status(200).json({ message: "Logged out successfully" });
};
