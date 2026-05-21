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

# YOLO for charger body only; red LED uses OpenCV
model_path = os.path.join(os.path.dirname(__file__), 'my_model.pt')
model = None
if YOLO is not None and os.path.exists(model_path):
    print(f"Loading YOLO model from {model_path}...")
    model = YOLO(model_path)
else:
    print("YOLO model not loaded — charger body detection disabled; OpenCV red LED still active.")

@app.route('/api/vision/detect-gateway', methods=['POST'])
def detect_gateway():
    if 'image' not in request.files:
        return jsonify({"success": False, "errorMessage": "No image provided."}), 400
        
    file = request.files['image']
    image_bytes = file.read()
    image = Image.open(io.BytesIO(image_bytes))
    
    chargerDetected = False
    if model is not None:
        results = model(image)
        for result in results:
            for box in result.boxes:
                cls_name = model.names[int(box.cls[0])].lower()
                if 'charger' in cls_name or 'gateway' in cls_name or 'body' in cls_name:
                    chargerDetected = True

    # Red LED via OpenCV HSV (not YOLO)
    temp_path = os.path.join(os.path.dirname(__file__), 'temp', f'gateway_{os.getpid()}.jpg')
    os.makedirs(os.path.dirname(temp_path), exist_ok=True)
    image.save(temp_path, format='JPEG')
    try:
        red_result = detect_red(temp_path)
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

    lightDetected = red_result.get('lightDetected', False)
    lightColor = red_result.get('lightColor', 'OFF')
    confidence = red_result.get('confidence', 0.0)

    return jsonify({
        "success": True,
        "chargerDetected": chargerDetected,
        "lightDetected": lightDetected,
        "lightColor": lightColor,
        "confidence": confidence,
        "opencvMethod": red_result.get('method'),
    })

if __name__ == '__main__':
    print("Starting Rexharge Vision Python Server on port 5000...")
    app.run(host='0.0.0.0', port=5000)
