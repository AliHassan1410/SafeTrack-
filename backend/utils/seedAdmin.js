import mongoose from "mongoose";
import dotenv from "dotenv";
import User from "../models/User.js";

import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, "../.env") });

const seedAdmin = async () => {
  const mongoUri = process.env.MONGO_URI || "mongodb://localhost:27017/safetrack";
  
  console.log("Connecting to MongoDB...");
  try {
    await mongoose.connect(mongoUri);
    console.log("Connected to MongoDB successfully! ✅");

    // Check if an admin user already exists
    const existingAdmin = await User.findOne({ role: "admin" });
    if (existingAdmin) {
      console.log(`Admin user already exists: ${existingAdmin.email} ✅`);
      process.exit(0);
    }

    // Create default admin user
    const adminEmail = "admin@safetrack.pk";
    const adminPassword = "AdminPass123";

    const adminUser = await User.create({
      name: "System Administrator",
      email: adminEmail,
      password: adminPassword,
      phone: "+923001234567",
      role: "admin",
      isEmailVerified: true,
    });

    console.log("Admin user created successfully! 🎉");
    console.log(`Email: ${adminUser.email}`);
    console.log(`Password: ${adminPassword}`);
    process.exit(0);
  } catch (error) {
    console.error("Error seeding admin user: ❌", error);
    process.exit(1);
  }
};

seedAdmin();
