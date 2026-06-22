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

    // 🚫 Suspension Check
    if (user.isSuspended) {
      return res.status(403).json({
        message: `Your account has been suspended${user.suspendedByName ? ` by ${user.suspendedByName}` : ''}. Please contact your administrator.`,
        isSuspended: true,
        suspendedByName: user.suspendedByName || null,
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

// ================= UPDATE USER PROFILE =================
export const updateUserProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const { name, phone, profilePic } = req.body;

    if (name) user.name = name.trim();
    if (phone !== undefined) user.phone = phone.trim();
    if (profilePic !== undefined) user.profilePic = profilePic;

    await user.save();

    res.status(200).json({
      message: "Profile updated successfully",
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profilePic: user.profilePic,
        isEmailVerified: user.isEmailVerified,
      }
    });

  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};


// ================= FORGOT PASSWORD =================
export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });

    if (!user) {
      // Return 200 even if user not found to prevent email enumeration attacks
      return res.status(200).json({ message: "If your email is registered, an OTP has been sent." });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 mins expiry

    user.resetPasswordOTP = otp;
    user.resetPasswordExpiresAt = otpExpiresAt;
    await user.save();

    // Send email
    const emailSent = await sendEmail({
      to: user.email,
      subject: "SafeTrack - Password Reset OTP",
      html: `
        <h2>Password Reset Request</h2>
        <p>Your password reset OTP is: <strong>${otp}</strong></p>
        <p>This OTP will expire in 15 minutes.</p>
        <p>If you did not request a password reset, please ignore this email.</p>
      `,
    });

    if (!emailSent) {
      return res.status(500).json({ message: "Error sending email. Please try again later." });
    }

    res.status(200).json({ message: "OTP sent successfully." });
  } catch (error) {
    console.error("Forgot Password Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ================= VERIFY RESET OTP =================
export const verifyResetOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ message: "Email and OTP are required" });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });

    if (!user || user.resetPasswordOTP !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (user.resetPasswordExpiresAt < new Date()) {
      return res.status(400).json({ message: "OTP has expired. Please request a new one." });
    }

    res.status(200).json({ message: "OTP verified successfully" });
  } catch (error) {
    console.error("Verify Reset OTP Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ================= RESET PASSWORD =================
export const resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({ message: "Email, OTP, and new password are required" });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: "Password must be at least 6 characters" });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() });

    if (!user || user.resetPasswordOTP !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (user.resetPasswordExpiresAt < new Date()) {
      return res.status(400).json({ message: "OTP has expired. Please request a new one." });
    }

    // Update password and clear OTP
    user.password = newPassword;
    user.resetPasswordOTP = undefined;
    user.resetPasswordExpiresAt = undefined;
    await user.save();

    res.status(200).json({ message: "Password reset successfully" });
  } catch (error) {
    console.error("Reset Password Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ================= GET ALL USERS (filtered by role) =================
export const getUsers = async (req, res) => {
  try {
    const { role } = req.query;
    const filter = {};
    if (role) {
      filter.role = role;
    }
    const users = await User.find(filter).select("-password");
    res.status(200).json({ users });
  } catch (error) {
    console.error("Get Users Error:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

// ================= SUSPEND RESPONDER (Admin can only suspend responders) =================
export const suspendResponder = async (req, res) => {
  try {
    const { id } = req.params;
    const suspender = await User.findById(req.user.id);

    // Verify the caller is an admin
    if (!suspender || (suspender.role !== "admin" && suspender.role !== "superadmin")) {
      return res.status(403).json({ message: "Forbidden" });
    }

    const target = await User.findById(id);
    if (!target) return res.status(404).json({ message: "User not found" });

    // Regular admins can only suspend responders
    if (suspender.role === "admin" && target.role !== "responder") {
      return res.status(403).json({ message: "Admins can only suspend responders" });
    }

    target.isSuspended = true;
    target.suspendedBy = suspender._id;
    target.suspendedByName = suspender.name;
    await target.save();

    res.status(200).json({ message: `${target.name} has been suspended.` });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ================= UNSUSPEND RESPONDER =================
export const unsuspendResponder = async (req, res) => {
  try {
    const { id } = req.params;
    const caller = await User.findById(req.user.id);

    if (!caller || (caller.role !== "admin" && caller.role !== "superadmin")) {
      return res.status(403).json({ message: "Forbidden" });
    }

    const target = await User.findById(id);
    if (!target) return res.status(404).json({ message: "User not found" });

    target.isSuspended = false;
    target.suspendedBy = null;
    target.suspendedByName = null;
    await target.save();

    res.status(200).json({ message: `${target.name} has been unsuspended.` });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ================= CREATE RESPONDER (Admin & Super Admin) =================
export const createResponder = async (req, res) => {
  try {
    const { name, email, password, phone, responderType } = req.body;
    
    // Check if the current user is an admin or superadmin
    const creator = await User.findById(req.user.id);
    if (!creator || (creator.role !== "admin" && creator.role !== "superadmin")) {
      return res.status(403).json({ message: "Forbidden: Admin or Super Admin access required" });
    }

    if (!name || !email || !password || !responderType) {
      return res.status(400).json({ message: "Name, email, password, and responder type are required" });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase().trim() });
    if (existingUser) {
      return res.status(400).json({ message: "Email is already registered" });
    }

    // Create the responder (email verified is true since admin created them directly)
    const responder = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      phone: phone ? phone.trim() : "",
      role: "responder",
      responderType,
      isEmailVerified: true,
    });

    // Send email with details
    await sendEmail({
      to: responder.email,
      subject: "Welcome to SafeTrack - Responder Account Created",
      html: `
        <h2>SafeTrack Responder Registration</h2>
        <p>Hello <strong>${responder.name}</strong>,</p>
        <p>An emergency responder account has been created for you by an administrator.</p>
        <p><strong>Login Details:</strong></p>
        <ul>
          <li><strong>Role:</strong> Responder (${responderType === 'medical' ? '🏥 Medical / Ambulance' : '🚔 Crime / Police'})</li>
          <li><strong>Email:</strong> ${responder.email}</li>
          <li><strong>Password:</strong> ${password}</li>
        </ul>
        <p>Please use these credentials to log in to the SafeTrack application.</p>
        <p>Stay safe!</p>
      `,
    });

    res.status(201).json({
      message: "Responder created successfully and credentials sent to email.",
      user: {
        _id: responder._id,
        name: responder.name,
        email: responder.email,
        phone: responder.phone,
        role: responder.role,
        responderType: responder.responderType,
      }
    });
  } catch (error) {
    console.error("Create Responder Error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
};
