import sys
import json
import os

_MODEL = None
_MODEL_PATH = None


def _get_model(model_path):
    global _MODEL, _MODEL_PATH
    if _MODEL is not None and _MODEL_PATH == model_path:
        return _MODEL
    from ultralytics import YOLO
    _MODEL = YOLO(model_path)
    _MODEL_PATH = model_path
    return _MODEL


def run_inference(image_path, model_path):
    try:
        model = _get_model(model_path)
    except ImportError:
        # Graceful fallback warning if ultralytics is not installed yet
        return {
            "success": False,
            "error": "Python package 'ultralytics' is not installed. Please run: py -m pip install ultralytics",
            "mock": True,
            "detections": [
                {
                    "class": "charger_body",
                    "confidence": 0.95,
                    "box": [50, 100, 400, 800]
                }
            ]
        }

    if not os.path.exists(model_path):
        return {
            "success": False,
            "error": f"Model weights not found at {model_path}",
            "detections": []
        }

    try:
        # Run inference (model stays cached for repeated calls in the same process)
        results = model(image_path, verbose=False, imgsz=480)
        
        detections = []
        for result in results:
            boxes = result.boxes
            for box in boxes:
                # Class name
                class_id = int(box.cls[0])
                class_name = model.names[class_id]
                
                # Confidence score
                confidence = float(box.conf[0])
                
                # Bounding box coordinates [x1, y1, x2, y2]
                xyxy = box.xyxy[0].tolist()
                
                detections.append({
                    "class": class_name,
                    "confidence": round(confidence, 4),
                    "box": [round(coord, 2) for coord in xyxy]
                })
                
        return {
            "success": True,
            "detections": detections
        }
        
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "detections": []
        }

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(json.dumps({
            "success": False,
            "error": "Usage: py yolo_inference.py <image_path> <model_path>"
        }))
        sys.exit(1)
        
    img_path = sys.argv[1]
    mod_path = sys.argv[2]
    
    result = run_inference(img_path, mod_path)
    print(json.dumps(result))
