import express from "express";
import mongoose from "mongoose";
import dotenv from "dotenv";
import cors from "cors";
import { createServer } from "http";
import { Server } from "socket.io";
import authRoutes from "./routes/authRoutes.js";
import incidentRoutes from "./routes/incidentRoutes.js";

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: "*" }
});

// ✅ Socket.io Logic for Live Tracking
io.on("connection", (socket) => {
  console.log("📱 User connected to Socket:", socket.id);

  // Join a room specific to an incident for live tracking
  socket.on("join_incident", (incidentId) => {
    socket.join(incidentId);
    console.log(`📍 User joined incident tracking room: ${incidentId}`);
  });

  // Responder sends live location -> Broadcast to Reporter
  socket.on("responder_location_update", (data) => {
    // data format: { incidentId, lat, lng, responderId }
    if (data.incidentId) {
      io.to(data.incidentId).emit("location_update", {
        lat: data.lat,
        lng: data.lng,
        responderId: data.responderId
      });
    }
  });

  socket.on("disconnect", () => {
    console.log("❌ User disconnected:", socket.id);
  });
});

// Export io so we can emit events from controllers (e.g. when a report is created)
export { io };

// ✅ Middleware (IMPORTANT ORDER)
app.use(cors({
  origin: "*"
}));

app.use(express.json());

// ✅ Routes
app.use("/api/auth", authRoutes);
app.use("/api/incidents", incidentRoutes);

// ✅ Test route
app.get("/", (req, res) => {
  res.send("SafeTrack Backend is Running 🚀 with Socket.io");
});

// ✅ Better error logging
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB Connected ✅");

    const PORT = process.env.PORT || 5000;

    // ✅ IMPORTANT FIX: bind to all interfaces using httpServer instead of app
    httpServer.listen(PORT, "0.0.0.0", () => {
      console.log(`Server & Socket.io running on port ${PORT} 🚀`);
    });
  })
  .catch((err) => {
    console.error("MongoDB Connection Error ❌", err);
  });