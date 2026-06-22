import express from "express";

// Traditional auth
import { registerUser, loginUser, getUserProfile, updateUserProfile, verifyEmail, forgotPassword, verifyResetOTP, resetPassword, getUsers, suspendResponder, unsuspendResponder, createResponder } from "../controllers/authController.js";


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
router.post("/forgot-password", forgotPassword);
router.post("/verify-reset-otp", verifyResetOTP);
router.post("/reset-password", resetPassword);

// Google OAuth — Flutter sends Google ID token here
router.post("/google", googleSignIn);

// ─────────────────────────────────────────────────────────────
// 🔒 Protected Routes (JWT required)
// ─────────────────────────────────────────────────────────────
router.get("/profile", authMiddleware, getUserProfile);
router.put("/profile", authMiddleware, updateUserProfile);
router.get("/profile/google", authMiddleware, getGoogleUserProfile);
router.get("/users", authMiddleware, getUsers);
router.post("/logout", authMiddleware, logout);
router.put("/suspend/:id", authMiddleware, suspendResponder);
router.put("/unsuspend/:id", authMiddleware, unsuspendResponder);
router.post("/responders", authMiddleware, createResponder);

export default router;