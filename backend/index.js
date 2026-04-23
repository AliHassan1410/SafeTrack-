import express from "express";
import mongoose from "mongoose";
import dotenv from "dotenv";
import cors from "cors";
import authRoutes from "./routes/authRoutes.js";
import incidentRoutes from "./routes/incidentRoutes.js";

dotenv.config();

const app = express();

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
  res.send("SafeTrack Backend is Running 🚀");
});

// ✅ Better error logging
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log("MongoDB Connected ✅");

    const PORT = process.env.PORT || 5000;

    // ✅ IMPORTANT FIX: bind to all interfaces
    app.listen(PORT, "0.0.0.0", () => {
      console.log(`Server running on port ${PORT} 🚀`);
    });
  })
  .catch((err) => {
    console.error("MongoDB Connection Error ❌", err);
  });