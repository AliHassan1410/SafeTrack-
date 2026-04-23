# scripts/train.py

from ultralytics import YOLO
import os

# -----------------------------
# Paths
# -----------------------------

dataset_yaml = r"dataset/images/guns-knives/data.yaml"   # your dataset YAML file
pretrained_weights = "model/yolov8n.pt"     # pretrained YOLOv8 weights
results_dir = "model/results"               # folder to save training results
experiment_name = "guns_knives_train"       # name for this training run

# Make sure results directory exists
os.makedirs(results_dir, exist_ok=True)

# -----------------------------
# Load YOLOv8 model
# -----------------------------
model = YOLO(pretrained_weights)

# -----------------------------
# Train the model
# -----------------------------
model.train(
    data=dataset_yaml,    # path to dataset YAML
    epochs=5,            # number of epochs (can increase if needed)
    batch=8,             # batch size
    imgsz=416,            # image size (YOLO recommends 640)
    project=results_dir,  # save results here
    name=experiment_name, 
    exist_ok=True,        # overwrite if folder exists
    workers=2
)

# -----------------------------
# Training completed
# -----------------------------
print("Training completed! Check results in:", os.path.join(results_dir, experiment_name))