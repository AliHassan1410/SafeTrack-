import express from "express";

// Traditional auth
import { registerUser, loginUser, getUserProfile, verifyEmail } from "../controllers/authController.js";

// Google OAuth auth
import { googleSignIn, getGoogleUserProfile, logout } from "../controllers/googleAuthController.js";

import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

// ─────────────────────────────────────────────────────────────
// 🔓 Public Routes (no token required)
// ─────────────────────────────────────────────────────────────

// Traditional email/password
router.post("/register", registerUser);
router.post("/verify-email", verifyEmail);
router.post("/login", loginUser);

// Google OAuth — Flutter sends Google ID token here
router.post("/google", googleSignIn);

// ─────────────────────────────────────────────────────────────
// 🔒 Protected Routes (JWT required)
// ─────────────────────────────────────────────────────────────
router.get("/profile", authMiddleware, getUserProfile);
router.get("/profile/google", authMiddleware, getGoogleUserProfile);
router.post("/logout", authMiddleware, logout);

export default router;