import User from "../models/User.js";
import Incident from "../models/Incident.js";
import sendEmail from "../utils/sendEmail.js";

// 1️⃣ CREATE LOWER LEVEL ADMIN
export const createAdmin = async (req, res) => {
  try {
    const { name, email, password, phone, city, lat, lng, radius } = req.body;

    if (!name || !email || !password || !city) {
      return res.status(400).json({ message: "Name, email, password, and city are required" });
    }

    const existingUser = await User.findOne({ email: email.toLowerCase().trim() });
    if (existingUser) {
      return res.status(400).json({ message: "Email is already registered" });
    }

    const admin = await User.create({
      name,
      email: email.toLowerCase().trim(),
      password,
      phone: phone || "",
      role: "admin",
      city,
      coverageArea: {
        lat: lat !== undefined ? parseFloat(lat) : null,
        lng: lng !== undefined ? parseFloat(lng) : null,
        radius: radius !== undefined ? parseFloat(radius) : 5,
      },
      isEmailVerified: true,
    });

    // Send email with credentials to admin
    await sendEmail({
      to: admin.email,
      subject: "Welcome to SafeTrack - Admin Account Created",
      html: `
        <h2>SafeTrack Admin Registration</h2>
        <p>Hello <strong>${admin.name}</strong>,</p>
        <p>A low-level administrator account has been created for you by the Super Admin.</p>
        <p><strong>Login Details:</strong></p>
        <ul>
          <li><strong>Role:</strong> Zone Administrator</li>
          <li><strong>City:</strong> ${admin.city}</li>
          <li><strong>Email:</strong> ${admin.email}</li>
          <li><strong>Password:</strong> ${password}</li>
        </ul>
        <p>Please use these credentials to log in to the SafeTrack Admin dashboard.</p>
        <p>Stay safe!</p>
      `,
    });

    res.status(201).json({
      message: "Admin created successfully and credentials sent to email",
      admin: {
        _id: admin._id,
        name: admin.name,
        email: admin.email,
        phone: admin.phone,
        city: admin.city,
        coverageArea: admin.coverageArea,
      }
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// 2️⃣ GET ALL LOW-LEVEL ADMINS
export const getAdmins = async (req, res) => {
  try {
    const admins = await User.find({ role: "admin" }).select("-password");
    res.status(200).json({ admins });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// 3️⃣ UPDATE LOW-LEVEL ADMIN
export const updateAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, password, phone, city, lat, lng, radius } = req.body;

    const admin = await User.findOne({ _id: id, role: "admin" });
    if (!admin) {
      return res.status(404).json({ message: "Admin not found" });
    }

    if (name) admin.name = name;
    if (email) admin.email = email.toLowerCase().trim();
    if (phone !== undefined) admin.phone = phone;
    if (city) admin.city = city;
    if (password) admin.password = password;

    if (lat !== undefined && lng !== undefined) {
      admin.coverageArea = {
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        radius: radius !== undefined ? parseFloat(radius) : admin.coverageArea.radius,
      };
    } else if (radius !== undefined) {
      admin.coverageArea.radius = parseFloat(radius);
    }

    await admin.save();

    res.status(200).json({
      message: "Admin updated successfully",
      admin: {
        _id: admin._id,
        name: admin.name,
        email: admin.email,
        phone: admin.phone,
        city: admin.city,
        coverageArea: admin.coverageArea,
      }
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// 4️⃣ DELETE LOW-LEVEL ADMIN
export const deleteAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    const admin = await User.findOneAndDelete({ _id: id, role: "admin" });
    if (!admin) {
      return res.status(404).json({ message: "Admin not found" });
    }
    res.status(200).json({ message: "Admin deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// 5️⃣ GET SYSTEM-WIDE STATS FOR SUPER ADMIN DASHBOARD
export const getStats = async (req, res) => {
  try {
    const totalAdmins = await User.countDocuments({ role: "admin" });
    const totalResponders = await User.countDocuments({ role: "responder" });
    const totalReporters = await User.countDocuments({ role: "reporter" });

    const totalIncidents = await Incident.countDocuments();
    const pendingIncidents = await Incident.countDocuments({ status: "pending" });
    const activeIncidents = await Incident.countDocuments({ status: { $in: ["active", "in_progress", "accepted"] } });
    const resolvedIncidents = await Incident.countDocuments({ status: "resolved" });
    const cancelledIncidents = await Incident.countDocuments({ status: "cancelled" });

    res.status(200).json({
      stats: {
        totalAdmins,
        totalResponders,
        totalReporters,
        totalIncidents,
        pendingIncidents,
        activeIncidents,
        resolvedIncidents,
        cancelledIncidents,
      }
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// 6️⃣ SUSPEND A USER (ADMIN or RESPONDER) — Super Admin only
export const suspendUser = async (req, res) => {
  try {
    const { id } = req.params;
    const suspender = await User.findById(req.user.id);

    const target = await User.findById(id);
    if (!target) return res.status(404).json({ message: "User not found" });
    if (target.role === "superadmin") {
      return res.status(403).json({ message: "Cannot suspend a Super Admin" });
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

// 7️⃣ UNSUSPEND A USER — Super Admin only
export const unsuspendUser = async (req, res) => {
  try {
    const { id } = req.params;
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
