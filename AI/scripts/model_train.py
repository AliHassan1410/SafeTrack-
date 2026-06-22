from ultralytics import YOLO
import os

# -----------------------------
# BASE PATH (IMPORTANT FIX)
# -----------------------------
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# -----------------------------
# Paths
# -----------------------------
dataset_yaml = os.path.join(BASE_DIR, "dataset", "images", "guns-knives-fire-accident", "data.yaml")

pretrained_weights = "yolov8n.pt"  # recommended starting point (NOT best.pt)

results_dir = os.path.join(BASE_DIR, "runs", "train")
experiment_name = "guns_knives_fire_accident_train"

os.makedirs(results_dir, exist_ok=True)

# -----------------------------
# Load model
# -----------------------------
model = YOLO(pretrained_weights)

# -----------------------------
# Train model
# -----------------------------
model.train(
    data=dataset_yaml,
    epochs=50,          # improved (5 is too low)
    batch=8,
    imgsz=640,          # better accuracy
    project=results_dir,
    name=experiment_name,
    exist_ok=True,
    workers=2
)

print("Training completed!")
print("Check results at:", os.path.join(results_dir, experiment_name))