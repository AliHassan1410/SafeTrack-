import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const userSchema = new mongoose.Schema(
  {
    // 👤 Name
    name: {
      type: String,
      required: true,
      trim: true,
    },

    // 📧 Email
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    // 🔒 Password (optional for Google users)
    password: {
      type: String,
      minlength: 6,
      default: null,
    },

    // 📱 Phone (optional for Google users)
    phone: {
      type: String,
      trim: true,
      default: "",
    },

    // 👥 Role
    role: {
      type: String,
      enum: ["reporter", "responder"],
      default: "reporter",
    },

    // 🚑 Responder Type (IMPORTANT)
    responderType: {
      type: String,
      enum: ["medical", "crime"],
      required: function () {
        return this.role === "responder";
      },
    },

    // 📍 Optional: Live location of responder (for tracking)
    currentLocation: {
      lat: Number,
      lng: Number,
    },

    // ─────────── Google OAuth Fields ───────────

    // 🔑 Google ID (unique identifier from Google)
    googleId: {
      type: String,
      default: null,
      sparse: true, // allows multiple null values while keeping uniqueness
    },

    // 🖼️ Profile Picture URL (from Google)
    profilePic: {
      type: String,
      default: null,
    },

    // 🌐 Auth Provider
    authProvider: {
      type: String,
      enum: ["local", "google"],
      default: "local",
    },

    // 📧 Email Verification
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    emailVerificationOTP: {
      type: String,
      default: null,
    },
    otpExpiresAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

// 🔐 Hash password before saving (only for local auth users)
userSchema.pre("save", async function () {
  if (!this.isModified("password") || !this.password) {
    return;
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// 🔑 Method to verify password
userSchema.methods.matchPassword = async function (enteredPassword) {
  if (!this.password) return false;
  return await bcrypt.compare(enteredPassword, this.password);
};

const User = mongoose.model("User", userSchema);

export default User;