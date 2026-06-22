import mongoose from "mongoose";
import dotenv from "dotenv";
import User from "../models/User.js";

import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, "../.env") });

const seedSuperAdmin = async () => {
  const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/safetrack";
  
  console.log("Connecting to MongoDB...");
  try {
    await mongoose.connect(mongoUri);
    console.log("Connected to MongoDB successfully! ✅");

    // Check if a super admin user already exists
    const existingSuperAdmin = await User.findOne({ role: "superadmin" });
    if (existingSuperAdmin) {
      console.log(`Super Admin user already exists: ${existingSuperAdmin.email} ✅`);
      process.exit(0);
    }

    // Create default super admin user
    const superAdminEmail = "superadmin@safetrack.pk";
    const superAdminPassword = "SuperAdminPass123";

    const superAdminUser = await User.create({
      name: "Super Administrator",
      email: superAdminEmail,
      password: superAdminPassword,
      phone: "+923009876543",
      role: "superadmin",
      isEmailVerified: true,
      city: "Lahore",
    });

    console.log("Super Admin user created successfully! 🎉");
    console.log(`Email: ${superAdminUser.email}`);
    console.log(`Password: ${superAdminPassword}`);
    process.exit(0);
  } catch (error) {
    console.error("Error seeding Super Admin user: ❌", error);
    process.exit(1);
  }
};

seedSuperAdmin();
