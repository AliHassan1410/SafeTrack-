import Incident from "../models/Incident.js";
import User from "../models/User.js";
import Notification from "../models/Notification.js";

/* ---------------------------------------
   1️⃣ CREATE INCIDENT (Reporter Side)
----------------------------------------*/
export const createIncident = async (req, res) => {
  try {
    const { title, type, description, location, imageUrl, address } = req.body;

    const incident = await Incident.create({
      reporter: req.user.id,
      title,
      type,
      description,
      imageUrl,
      location: {
        type: "Point",
        coordinates: [location.lng, location.lat],
        address: address || location.address,
      },
    });

    // Find responders matching the incident type
    const responders = await User.find({ role: "responder", responderType: type });

    // Create notifications for them
    const notificationsToInsert = responders.map(r => ({
      recipient: r._id,
      title: "New Emergency Alert",
      message: `${type.toUpperCase()} incident reported: ${title}`,
      type: "emergency_alert",
      relatedIncident: incident._id,
    }));

    let insertedNotifications = [];
    if (notificationsToInsert.length > 0) {
       insertedNotifications = await Notification.insertMany(notificationsToInsert);
    }

    // Notify connected clients about the new incident
    import("../index.js").then(({ io }) => {
      io.emit("new_incident", incident);
      
      // Emit notifications
      insertedNotifications.forEach(notif => {
        io.emit("new_notification", notif);
      });
    }).catch(err => console.error("Socket emit error:", err));

    res.status(201).json({
      message: "Incident created successfully",
      incident,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ---------------------------------------
   2️⃣ GET REPORTER INCIDENTS
----------------------------------------*/
export const getIncidents = async (req, res) => {
  try {
    const currentUser = await User.findById(req.user.id);
    let incidents;

    if (currentUser && (currentUser.role === "admin" || currentUser.role === "superadmin")) {
      // If low-level admin has a coverage area defined, filter incidents within that area
      if (
        currentUser.role === "admin" &&
        currentUser.coverageArea &&
        currentUser.coverageArea.lat !== null &&
        currentUser.coverageArea.lng !== null
      ) {
        // Convert radius in km to radians for $centerSphere (Earth radius = 6378.1 km)
        const radiusInRadians = currentUser.coverageArea.radius / 6378.1;

        incidents = await Incident.find({
          location: {
            $geoWithin: {
              $centerSphere: [
                [currentUser.coverageArea.lng, currentUser.coverageArea.lat],
                radiusInRadians,
              ],
            },
          },
        })
          .populate("reporter", "name email phone")
          .populate("assignedResponder", "name email phone")
          .sort({ createdAt: -1 });
      } else {
        // Superadmin or admin without coverage area sees all incidents
        incidents = await Incident.find()
          .populate("reporter", "name email phone")
          .populate("assignedResponder", "name email phone")
          .sort({ createdAt: -1 });
      }
    } else {
      // Regular user / reporter
      incidents = await Incident.find({
        reporter: req.user.id,
      }).sort({ createdAt: -1 });
    }

    res.status(200).json(incidents);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ---------------------------------------
   3️⃣ NEARBY INCIDENTS (RESPONDER SIDE)
   🔥 KEY FEATURE: 2 KM + TYPE FILTER
----------------------------------------*/
export const getNearbyIncidents = async (req, res) => {
  try {
    const { lat, lng, type } = req.query;

    const incidents = await Incident.find({
      status: "pending",
      type: type, // medical / crime
      location: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [parseFloat(lng), parseFloat(lat)],
          },
          $maxDistance: 2000, // 2 km radius
        },
      },
    }).populate("reporter", "name phone");

    res.status(200).json(incidents);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ---------------------------------------
   4️⃣ ACCEPT INCIDENT (RESPONDER)
----------------------------------------*/
export const acceptIncident = async (req, res) => {
  try {
    const incident = await Incident.findById(req.params.id);

    if (!incident) {
      return res.status(404).json({ message: "Incident not found" });
    }

    incident.status = "accepted";
    incident.assignedResponder = req.user.id;
    incident.acceptedAt = new Date();

    await incident.save();

    res.status(200).json({
      message: "Incident accepted",
      incident,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ---------------------------------------
   5️⃣ UPDATE RESPONDER LOCATION (LIVE TRACKING)
----------------------------------------*/
export const updateResponderLocation = async (req, res) => {
  try {
    const { lat, lng } = req.body;

    const incident = await Incident.findByIdAndUpdate(
      req.params.id,
      {
        responderLocation: { lat, lng },
      },
      { new: true }
    );

    res.status(200).json(incident);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ---------------------------------------
   6️⃣ GET ASSIGNED INCIDENTS (RESPONDER)
----------------------------------------*/
export const getAssignedIncidents = async (req, res) => {
  try {
    const incidents = await Incident.find({
      assignedResponder: req.user.id,
    })
      .populate("reporter", "name phone")
      .sort({ updatedAt: -1 });

    res.status(200).json(incidents);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ---------------------------------------
   7️⃣ COMPLETE INCIDENT (RESPONDER)
----------------------------------------*/
export const completeIncident = async (req, res) => {
  try {
    const incident = await Incident.findById(req.params.id);

    if (!incident) {
      return res.status(404).json({ message: "Incident not found" });
    }

    if (incident.assignedResponder.toString() !== req.user.id) {
      return res.status(403).json({ message: "Not authorized to complete this incident" });
    }

    incident.status = "completed";
    incident.resolvedAt = new Date();

    await incident.save();

    res.status(200).json({
      message: "Incident marked as completed",
      incident,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ---------------------------------------
   8️⃣ UPDATE INCIDENT STATUS (ADMIN)
----------------------------------------*/
export const updateIncidentStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const currentUser = await User.findById(req.user.id);
    if (!currentUser || (currentUser.role !== "admin" && currentUser.role !== "superadmin")) {
      return res.status(403).json({ message: "Not authorized to perform this action" });
    }

    const incident = await Incident.findById(req.params.id);
    if (!incident) {
      return res.status(404).json({ message: "Incident not found" });
    }

    incident.status = status;
    if (status === "resolved" || status === "completed") {
      incident.resolvedAt = new Date();
    }
    await incident.save();

    // Notify clients of the update
    import("../index.js").then(({ io }) => {
      io.emit("incident_updated", incident);
    }).catch(err => console.error("Socket emit error:", err));

    res.status(200).json({
      message: "Incident status updated successfully",
      incident,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

/* ---------------------------------------
   9️⃣ ASSIGN RESPONDER (ADMIN)
----------------------------------------*/
export const assignResponder = async (req, res) => {
  try {
    const { responderId } = req.body;
    const currentUser = await User.findById(req.user.id);
    if (!currentUser || (currentUser.role !== "admin" && currentUser.role !== "superadmin")) {
      return res.status(403).json({ message: "Not authorized to perform this action" });
    }

    const incident = await Incident.findById(req.params.id);
    if (!incident) {
      return res.status(404).json({ message: "Incident not found" });
    }

    const responder = await User.findById(responderId);
    if (!responder || responder.role !== "responder") {
      return res.status(400).json({ message: "Invalid responder selected" });
    }

    incident.assignedResponder = responderId;
    // When assigned by admin, it becomes active/accepted for the responder
    incident.status = "accepted";
    incident.acceptedAt = new Date();
    
    await incident.save();

    // Populate reporter and assignedResponder to return complete data
    const updatedIncident = await Incident.findById(incident._id)
      .populate("reporter", "name phone")
      .populate("assignedResponder", "name phone");

    // Notify clients
    import("../index.js").then(({ io }) => {
      io.emit("incident_assigned", updatedIncident);
      io.emit("incident_updated", updatedIncident);
    }).catch(err => console.error("Socket emit error:", err));

    res.status(200).json({
      message: "Responder assigned successfully",
      incident: updatedIncident,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};