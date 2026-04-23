from ultralytics import YOLO
import cv2
from tkinter import Tk, filedialog
import os
from datetime import datetime

# Load trained model
model = YOLO("runs/detect/model/results/guns_knives_train/weights/best.pt")

# Folder for saving detections
os.makedirs("detections", exist_ok=True)


# -----------------------------
# Live Camera Detection
# -----------------------------
def live_camera_detection():

    cap = cv2.VideoCapture(0)

    cv2.namedWindow("Live Weapon Detection", cv2.WINDOW_NORMAL)
    cv2.setWindowProperty("Live Weapon Detection",
                          cv2.WND_PROP_FULLSCREEN,
                          cv2.WINDOW_FULLSCREEN)

    while True:
        ret, frame = cap.read()

        if not ret:
            print("Camera not working")
            break

        results = model(frame, conf=0.5)
        annotated_frame = results[0].plot()

        for box in results[0].boxes:

            class_id = int(box.cls[0])
            class_name = model.names[class_id]

            # -----------------------------
            # KNIFE DETECTION
            # -----------------------------
            if class_name == "knife":

                cv2.putText(
                    annotated_frame,
                    "ALERT: KNIFE DETECTED",
                    (50, 80),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1.2,
                    (0, 0, 255),
                    3
                )

                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"detections/knife_{timestamp}.jpg"

                cv2.imwrite(filename, frame)
                print(f"⚠ Knife detected! Image saved: {filename}")

            # -----------------------------
            # GUN / PISTOL DETECTION
            # -----------------------------
            if class_name == "pistol":

                cv2.putText(
                    annotated_frame,
                    "ALERT: GUN DETECTED",
                    (50, 130),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1.2,
                    (0, 0, 255),
                    3
                )

                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"detections/gun_{timestamp}.jpg"

                cv2.imwrite(filename, frame)
                print(f"⚠ Gun detected! Image saved: {filename}")

        cv2.imshow("Live Weapon Detection", annotated_frame)

        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()


# -----------------------------
# Image Upload Detection
# -----------------------------
def image_upload_detection():

    root = Tk()
    root.withdraw()

    file_path = filedialog.askopenfilename(
        title="Select Image",
        filetypes=[("Image files", "*.jpg *.jpeg *.png")]
    )

    if file_path:

        results = model(file_path, conf=0.5)
        img = results[0].plot()

        for box in results[0].boxes:

            class_id = int(box.cls[0])
            class_name = model.names[class_id]

            if class_name == "knife":
                cv2.putText(
                    img,
                    "ALERT: KNIFE DETECTED",
                    (50, 80),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1.2,
                    (0, 0, 255),
                    3
                )

            if class_name == "pistol":
                cv2.putText(
                    img,
                    "ALERT: GUN DETECTED",
                    (50, 130),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    1.2,
                    (0, 0, 255),
                    3
                )

        cv2.namedWindow("Detection Result", cv2.WINDOW_NORMAL)
        cv2.resizeWindow("Detection Result", 1200, 800)

        cv2.imshow("Detection Result", img)
        cv2.waitKey(0)
        cv2.destroyAllWindows()

    else:
        print("No image selected")


# -----------------------------
# MAIN MENU
# -----------------------------
while True:

    print("\n==============================")
    print(" Weapon Detection System ")
    print("==============================")
    print("1️⃣ Live Camera Detection")
    print("2️⃣ Upload Image From Gallery")
    print("3️⃣ Exit")

    choice = input("Enter choice: ")

    if choice == "1":
        live_camera_detection()

    elif choice == "2":
        image_upload_detection()

    elif choice == "3":
        print("Program closed")
        break

    else:
        print("Invalid option. Try again.")