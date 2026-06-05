import os
import io
import sys
from flask import Flask, request, jsonify
from PIL import Image

# OpenCV red LED helper (same script as Express server)
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'services'))
from opencv_red_detect import detect_red

try:
    from ultralytics import YOLO
except ImportError:
    YOLO = None

app = Flask(__name__)

# YOLO for charger body only; red LED uses OpenCV inside the charger ROI
model_path = os.path.join(os.path.dirname(__file__), 'my_model.pt')
model = None
if YOLO is not None and os.path.exists(model_path):
    print(f"Loading YOLO model from {model_path}...")
    model = YOLO(model_path)
else:
    print("YOLO model not loaded — charger body detection disabled; red LED scan skipped without ROI.")


def _is_charger_class(class_name):
    name = (class_name or '').lower()
    return 'charger' in name or 'gateway' in name or 'body' in name


def _pick_charger_box(results):
    best = None
    best_conf = -1.0
    for result in results:
        for box in result.boxes:
            cls_name = model.names[int(box.cls[0])]
            if not _is_charger_class(cls_name):
                continue
            conf = float(box.conf[0])
            if conf > best_conf:
                best_conf = conf
                best = box.xyxy[0].tolist()
    return best


@app.route('/api/vision/detect-gateway', methods=['POST'])
def detect_gateway():
    if 'image' not in request.files:
        return jsonify({"success": False, "errorMessage": "No image provided."}), 400

    file = request.files['image']
    image_bytes = file.read()
    image = Image.open(io.BytesIO(image_bytes))

    charger_detected = False
    charger_box = None
    if model is not None:
        results = model(image, verbose=False)
        charger_box = _pick_charger_box(results)
        charger_detected = charger_box is not None

    temp_path = os.path.join(os.path.dirname(__file__), 'temp', f'gateway_{os.getpid()}.jpg')
    os.makedirs(os.path.dirname(temp_path), exist_ok=True)
    image.save(temp_path, format='JPEG')

    try:
        if charger_detected and charger_box:
            red_result = detect_red(temp_path, charger_box)
        else:
            red_result = {
                "success": True,
                "lightDetected": False,
                "lightColor": "OFF",
                "confidence": 0.0,
                "method": "skipped_no_charger",
            }
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    return jsonify({
        "success": True,
        "chargerDetected": charger_detected,
        "lightDetected": red_result.get('lightDetected', False),
        "lightColor": red_result.get('lightColor', 'OFF'),
        "confidence": red_result.get('confidence', 0.0),
        "opencvMethod": red_result.get('method'),
        "chargerBox": charger_box,
    })


@app.route('/api/vision/detect-red-light', methods=['POST'])
def detect_red_light():
    if 'image' not in request.files:
        return jsonify({"success": False, "errorMessage": "No image provided."}), 400

    file = request.files['image']
    image_bytes = file.read()
    image = Image.open(io.BytesIO(image_bytes))

    charger_box = None
    if model is not None:
        results = model(image, verbose=False)
        charger_box = _pick_charger_box(results)

    if not charger_box:
        return jsonify({
            "success": True,
            "lightDetected": False,
            "lightColor": "OFF",
            "confidence": 0.0,
            "opencvMethod": "skipped_no_charger",
        })

    temp_path = os.path.join(os.path.dirname(__file__), 'temp', f'red_{os.getpid()}.jpg')
    os.makedirs(os.path.dirname(temp_path), exist_ok=True)
    image.save(temp_path, format='JPEG')
    try:
        red_result = detect_red(temp_path, charger_box)
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    return jsonify({
        "success": red_result.get('success', True),
        "lightDetected": red_result.get('lightDetected', False),
        "lightColor": red_result.get('lightColor', 'OFF'),
        "confidence": red_result.get('confidence', 0.0),
        "opencvMethod": red_result.get('method'),
        "chargerBox": charger_box,
    })


if __name__ == '__main__':
    print("Starting Rexharge Vision Python Server on port 5000...")
    app.run(host='0.0.0.0', port=5000)
