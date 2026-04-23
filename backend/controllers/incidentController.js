import Incident from "../models/Incident.js";

/* ---------------------------------------
   1️⃣ CREATE INCIDENT (Reporter Side)
----------------------------------------*/
export const createIncident = async (req, res) => {
  try {
    const { title, type, description, location } = req.body;

    const incident = await Incident.create({
      reporter: req.user.id,
      title,
      type,
      description,
      location: {
        type: "Point",
        coordinates: [location.lng, location.lat], // 🔥 IMPORTANT ORDER
      },
    });

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
    const incidents = await Incident.find({
      reporter: req.user.id,
    }).sort({ createdAt: -1 });

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