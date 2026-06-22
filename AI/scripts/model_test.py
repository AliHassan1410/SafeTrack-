from ultralytics import YOLO
import cv2
from tkinter import Tk, filedialog
import os

# -----------------------------
# LOAD MODEL (FIXED PATH)
# -----------------------------
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
model_path = os.path.join(BASE_DIR, "runs", "train", "weights", "best.pt")

model = YOLO(model_path)

print("Model Classes:", model.names)


# -----------------------------
# LIVE CAMERA DETECTION
# -----------------------------
def live_camera():

    cap = cv2.VideoCapture(0)

    while True:
        ret, frame = cap.read()
        if not ret:
            print("Camera not working")
            break

        results = model(frame, conf=0.5)
        frame = results[0].plot()

        cv2.imshow("Live Detection - SafeTrack", frame)

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()


# -----------------------------
# IMAGE DETECTION
# -----------------------------
def image_detection():

    root = Tk()
    root.withdraw()

    file_path = filedialog.askopenfilename(
        title="Select Image",
        filetypes=[("Image files", "*.jpg *.jpeg *.png")]
    )

    if not file_path:
        print("No image selected")
        return

    results = model(file_path, conf=0.5)
    img = results[0].plot()

    cv2.imshow("Image Detection - SafeTrack", img)
    cv2.waitKey(0)
    cv2.destroyAllWindows()


# -----------------------------
# MAIN MENU
# -----------------------------
while True:

    print("\n==============================")
    print(" SafeTrack Testing System ")
    print("==============================")
    print("1️⃣ Live Camera Test")
    print("2️⃣ Image Test")
    print("3️⃣ Exit")

    choice = input("Enter choice: ")

    if choice == "1":
        live_camera()

    elif choice == "2":
        image_detection()

    elif choice == "3":
        print("Exited")
        break

    else:
        print("Invalid choice")