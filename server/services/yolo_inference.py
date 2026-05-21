import sys
import json
import os

def run_inference(image_path, model_path):
    try:
        from ultralytics import YOLO
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
        # Load the custom trained model (YOLOv8/v11 .pt weights)
        model = YOLO(model_path)
        
        # Run inference
        results = model(image_path, verbose=False)
        
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
