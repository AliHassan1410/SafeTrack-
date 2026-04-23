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

    // 🔒 Password
    password: {
      type: String,
      required: true,
      minlength: 6,
    },

    // 📱 Phone
    phone: {
      type: String,
      required: true,
      trim: true,
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
        return this.role === "responder"; // only required for responders
      },
    },

    // 📍 Optional: Live location of responder (for tracking)
    currentLocation: {
      lat: Number,
      lng: Number,
    },
  },
  { timestamps: true }
);

// 🔐 Hash password before saving
userSchema.pre("save", async function () {
  if (!this.isModified("password")) {
    return;
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// 🔑 Method to verify password
userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

const User = mongoose.model("User", userSchema);

export default User;