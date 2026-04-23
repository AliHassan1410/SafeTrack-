import express from "express";
import {
  createIncident,
  getIncidents,
  getNearbyIncidents,
  acceptIncident,
  updateResponderLocation,
} from "../controllers/incidentController.js";

import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

/* ---------------------------------------
   👤 REPORTER ROUTES
----------------------------------------*/

// Get reporter's own incidents
router.get("/", authMiddleware, getIncidents);

// Create incident
router.post("/", authMiddleware, createIncident);

/* ---------------------------------------
   🚑 RESPONDER ROUTES
----------------------------------------*/

// Get nearby incidents (2km + type filter)
router.get("/nearby", authMiddleware, getNearbyIncidents);

// Accept incident
router.put("/:id/accept", authMiddleware, acceptIncident);

// Update responder live location (tracking)
router.put("/:id/location", authMiddleware, updateResponderLocation);

export default router;