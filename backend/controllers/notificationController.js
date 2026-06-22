import Notification from "../models/Notification.js";

// ================= GET NOTIFICATIONS =================
export const getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ recipient: req.user.id })
      .populate("relatedIncident", "title type location status")
      .sort({ createdAt: -1 });
      
    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ================= MARK AS READ =================
export const markAsRead = async (req, res) => {
  try {
    await Notification.updateMany(
      { recipient: req.user.id, isUnread: true },
      { $set: { isUnread: false } }
    );
    res.status(200).json({ message: "Notifications marked as read" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};
