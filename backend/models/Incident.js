import mongoose from "mongoose";

const incidentSchema = new mongoose.Schema(
  {
    // 👤 Who reported
    reporter: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    // 🚨 Type of incident (IMPORTANT for filtering)
    type: {
      type: String,
      enum: ["medical", "crime"], // restrict values
      required: true,
    },

    // 📝 Title
    title: {
      type: String,
      required: true,
      default: "Incident",
    },

    // 📄 Description
    description: {
      type: String,
    },

    // 📍 LOCATION (UPDATED for geospatial queries)
    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [lng, lat]
        required: true,
      },
    },

    // 📊 Status of incident
    status: {
      type: String,
      enum: ["pending", "accepted", "completed"],
      default: "pending",
    },

    // 🚑 Assigned responder
    assignedResponder: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    // 📡 Live responder location (for tracking - optional)
    responderLocation: {
      lat: Number,
      lng: Number,
    },
  },
  { timestamps: true }
);

// 🔥 VERY IMPORTANT (for 2km filtering)
incidentSchema.index({ location: "2dsphere" });

export default mongoose.model("Incident", incidentSchema);