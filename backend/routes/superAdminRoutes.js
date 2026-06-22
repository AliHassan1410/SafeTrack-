import express from "express";
import { createAdmin, getAdmins, updateAdmin, deleteAdmin, getStats, suspendUser, unsuspendUser } from "../controllers/superAdminController.js";

import authMiddleware from "../middleware/authMiddleware.js";
import User from "../models/User.js";

const router = express.Router();

// Middleware to check if the user is a Super Admin
const superAdminOnly = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user || user.role !== "superadmin") {
      return res.status(403).json({ message: "Forbidden: Super Admin access required" });
    }
    next();
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// All superadmin routes require authentication and superadmin privileges
router.use(authMiddleware, superAdminOnly);

router.post("/admins", createAdmin);
router.get("/admins", getAdmins);
router.put("/admins/:id", updateAdmin);
router.delete("/admins/:id", deleteAdmin);
router.get("/stats", getStats);
router.put("/suspend/:id", suspendUser);
router.put("/unsuspend/:id", unsuspendUser);


export default router;
