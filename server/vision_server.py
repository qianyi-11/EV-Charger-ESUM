import os
import io
from flask import Flask, request, jsonify
from PIL import Image

try:
    from ultralytics import YOLO
except ImportError:
    print("Please install ultralytics and flask: pip install ultralytics flask pillow")
    exit(1)

app = Flask(__name__)

# Load the model
model_path = os.path.join(os.path.dirname(__file__), 'my_model.pt')
if not os.path.exists(model_path):
    print(f"ERROR: Model not found at {model_path}. Please copy your my_model.pt here!")
    model = None
else:
    print(f"Loading YOLO model from {model_path}...")
    model = YOLO(model_path)

@app.route('/api/vision/detect-gateway', methods=['POST'])
def detect_gateway():
    if model is None:
        return jsonify({"success": False, "errorMessage": "Model my_model.pt not loaded on server."}), 500
        
    if 'image' not in request.files:
        return jsonify({"success": False, "errorMessage": "No image provided."}), 400
        
    file = request.files['image']
    image_bytes = file.read()
    image = Image.open(io.BytesIO(image_bytes))
    
    # Run YOLO inference
    results = model(image)
    
    chargerDetected = False
    lightDetected = False
    lightColor = "OFF"
    
    # Process YOLO results 
    # (assuming your model detects classes like 'charger', 'red_light', 'flicker', etc.)
    for result in results:
        boxes = result.boxes
        for box in boxes:
            cls_id = int(box.cls[0])
            cls_name = model.names[cls_id].lower()
            
            if 'charger' in cls_name:
                chargerDetected = True
            elif 'red' in cls_name:
                lightDetected = True
                lightColor = "RED"
            elif 'flicker' in cls_name or 'blink' in cls_name:
                lightDetected = True
                lightColor = "FLICKER"
            elif 'light' in cls_name:
                lightDetected = True
                
    return jsonify({
        "success": True,
        "chargerDetected": chargerDetected,
        "lightDetected": lightDetected,
        "lightColor": lightColor,
        "confidence": 0.95
    })

if __name__ == '__main__':
    print("Starting Rexharge Vision Python Server on port 5000...")
    app.run(host='0.0.0.0', port=5000)
