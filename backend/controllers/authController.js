import User from "../models/User.js";
import jwt from "jsonwebtoken";
import sendEmail from "../utils/sendEmail.js";

// 🔐 Generate JWT Token
const generateToken = (id) => {
  return jwt.sign(
    { id },
    process.env.JWT_SECRET || "fallback_secret",
    { expiresIn: "30d" }
  );
};

// ================= REGISTER USER =================
export const registerUser = async (req, res) => {
  try {
    const { name, email, password, phone, role, responderType } = req.body;

    // ✅ 1. Required fields
    if (!name || !email || !password || !role) {
      return res.status(400).json({
        message: "All required fields must be filled",
      });
    }

    // ✅ 2. Email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        message: "Invalid email format",
      });
    }

    // ✅ 3. Password validation
    if (password.length < 6) {
      return res.status(400).json({
        message: "Password must be at least 6 characters",
      });
    }

    // ✅ 4. Role validation
    if (!["reporter", "responder"].includes(role)) {
      return res.status(400).json({
        message: "Invalid role selected",
      });
    }

    // ✅ 5. Responder validation (IMPORTANT)
    if (role === "responder" && !responderType) {
      return res.status(400).json({
        message: "responderType is required for responder",
      });
    }

    // ✅ 6. Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins expiry

    // ✅ 7. Check existing user
    let user = await User.findOne({ email });

    if (user) {
      if (user.isEmailVerified) {
        return res.status(400).json({
          message: "User already exists and is verified. Please log in.",
        });
      } else {
        // Update existing unverified user with new OTP and potentially new details
        user.name = name.trim();
        user.password = password; // Will be hashed by pre-save hook
        user.phone = phone ? phone.trim() : "";
        user.role = role;
        user.responderType = role === "responder" ? responderType : null;
        user.emailVerificationOTP = otp;
        user.otpExpiresAt = otpExpiresAt;
        await user.save();
      }
    } else {
      // Create new user
      user = await User.create({
        name: name.trim(),
        email: email.toLowerCase().trim(),
        password,
        phone: phone ? phone.trim() : "",
        role,
        responderType: role === "responder" ? responderType : null,
        isEmailVerified: false,
        emailVerificationOTP: otp,
        otpExpiresAt,
      });
    }

    // ✅ 8. Send OTP Email
    const emailSent = await sendEmail({
      to: user.email,
      subject: "SafeTrack - Verify your Email",
      html: `
        <h2>Welcome to SafeTrack!</h2>
        <p>Your email verification OTP is: <strong>${otp}</strong></p>
        <p>This OTP will expire in 15 minutes.</p>
        <p>Please enter this code in the app to complete your registration.</p>
      `,
    });

    if (!emailSent) {
      // It's a good practice to not fail registration completely if email fails, 
      // but in this case, verification is required.
      return res.status(500).json({
        message: "Error sending verification email. Please try again later.",
      });
    }

    // ✅ 9. Response
    res.status(201).json({
      message: "OTP sent to email. Please verify to complete registration.",
      email: user.email,
      requiresVerification: true
    });

  } catch (error) {
    console.error("Register Error:", error);

    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

// ================= VERIFY EMAIL (OTP) =================
export const verifyEmail = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ message: "Email and OTP are required" });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: "Email is already verified. Please log in." });
    }

    if (user.emailVerificationOTP !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (user.otpExpiresAt < new Date()) {
      return res.status(400).json({ message: "OTP has expired. Please register again to get a new one." });
    }

    // Success! Verify user
    user.isEmailVerified = true;
    user.emailVerificationOTP = undefined;
    user.otpExpiresAt = undefined;
    await user.save();

    // Log the user in immediately
    res.status(200).json({
      message: "Email verified successfully",
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        responderType: user.responderType,
        token: generateToken(user._id),
      },
    });
  } catch (error) {
    console.error("Verify Email Error:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

// ================= LOGIN USER =================
export const loginUser = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    // 🔴 Required fields
    if (!email || !password || !role) {
      return res.status(400).json({
        message: "Email, password and role are required",
      });
    }

    // 🔴 Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        message: "Invalid email format",
      });
    }

    // 🔴 Find user WITH ROLE CHECK
    const user = await User.findOne({
      email: email.toLowerCase().trim(),
      role: role,
    });

    if (!user) {
      return res.status(401).json({
        message: "Invalid credentials or wrong login role",
      });
    }

    if (!user.isEmailVerified && user.authProvider === "local") {
      return res.status(401).json({
        message: "Please verify your email before logging in. If you lost the code, try registering again.",
        requiresVerification: true
      });
    }

    // 🔴 Password check
    const isMatch = await user.matchPassword(password);

    if (!isMatch) {
      return res.status(401).json({
        message: "Invalid email or password",
      });
    }

    // ✅ SUCCESS
    res.status(200).json({
      message: "Logged in successfully",
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        responderType: user.responderType,
        token: generateToken(user._id),
      },
    });

  } catch (error) {
    console.error("Login Error:", error);

    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

// ================= GET USER PROFILE =================
export const getUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json(user);

  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};