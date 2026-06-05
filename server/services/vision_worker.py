"""
Persistent vision worker — loads YOLO once, serves JSON-line requests on stdin.

Usage: python vision_worker.py <model_path>
Protocol: one JSON object per line in, one JSON object per line out.
"""
import json
import os
import sys

# Import red LED helper from same directory
sys.path.insert(0, os.path.dirname(__file__))
from opencv_red_detect import detect_red

_MODEL = None
_MODEL_PATH = None
_IMGSZ = 480


def _load_model(model_path):
    global _MODEL, _MODEL_PATH
    if _MODEL is not None and _MODEL_PATH == model_path:
        return _MODEL
    from ultralytics import YOLO
    _MODEL = YOLO(model_path)
    _MODEL_PATH = model_path
    return _MODEL


def _is_charger_class(class_name):
    name = (class_name or "").lower()
    return "charger" in name or "gateway" in name or "body" in name


def _pick_charger_box(detections):
    charger_dets = [d for d in detections if _is_charger_class(d.get("class"))]
    if not charger_dets:
        return None
    best = max(charger_dets, key=lambda d: d.get("confidence", 0))
    box = best.get("box")
    return box if isinstance(box, list) and len(box) == 4 else None


def _run_yolo(image_path, model_path, imgsz=None, conf=None):
    try:
        model = _load_model(model_path)
    except ImportError:
        return {
            "success": False,
            "mock": True,
            "error": "ultralytics is not installed",
            "detections": [
                {"class": "charger_body", "confidence": 0.95, "box": [50, 100, 400, 800]}
            ],
        }

    if not os.path.exists(model_path):
        return {"success": False, "error": f"Model weights not found at {model_path}", "detections": []}

    if not os.path.exists(image_path):
        return {"success": False, "error": f"Image not found: {image_path}", "detections": []}

    try:
        infer_kwargs = {"verbose": False, "imgsz": imgsz or _IMGSZ}
        if conf is not None:
            infer_kwargs["conf"] = conf
        results = model(image_path, **infer_kwargs)
        detections = []
        for result in results:
            for box in result.boxes:
                class_id = int(box.cls[0])
                detections.append({
                    "class": model.names[class_id],
                    "confidence": round(float(box.conf[0]), 4),
                    "box": [round(float(c), 2) for c in box.xyxy[0].tolist()],
                })
        return {"success": True, "detections": detections}
    except Exception as e:
        return {"success": False, "error": str(e), "detections": []}


def _run_gateway(image_path, model_path):
    yolo_result = _run_yolo(image_path, model_path)
    charger_box = _pick_charger_box(yolo_result.get("detections", []))

    if yolo_result.get("mock") and not charger_box:
        charger_box = yolo_result.get("detections", [{}])[0].get("box")

    charger_detected = charger_box is not None

    if charger_detected and charger_box:
        red_result = detect_red(image_path, charger_box)
    else:
        red_result = {
            "success": True,
            "lightDetected": False,
            "lightColor": "OFF",
            "confidence": 0.0,
            "method": "skipped_no_charger",
        }

    return {
        "success": True,
        "yolo": yolo_result,
        "chargerDetected": charger_detected,
        "chargerBox": charger_box,
        "lightDetected": red_result.get("lightDetected", False),
        "lightColor": red_result.get("lightColor", "OFF"),
        "confidence": red_result.get("confidence", 0.0),
        "opencvMethod": red_result.get("method"),
        "detections": yolo_result.get("detections", []),
        "yoloSuccess": yolo_result.get("success", False),
        "mock": yolo_result.get("mock", False),
        "warning": yolo_result.get("error"),
    }


def _handle_request(req, model_path):
    cmd = req.get("cmd", "yolo")
    image_path = req.get("image")

    if not image_path:
        return {"success": False, "error": "Missing image path"}

    if cmd == "gateway":
        return _run_gateway(image_path, model_path)
    if cmd == "yolo":
        return _run_yolo(
            image_path,
            model_path,
            imgsz=req.get("imgsz"),
            conf=req.get("conf"),
        )
    if cmd == "isolator":
        # Higher resolution + lower conf — isolator switches are small in frame.
        return _run_yolo(image_path, model_path, imgsz=640, conf=0.12)
    if cmd == "red":
        box = req.get("box")
        return detect_red(image_path, box)
    if cmd == "ping":
        return {"success": True, "pong": True, "modelLoaded": _MODEL is not None}

    return {"success": False, "error": f"Unknown cmd: {cmd}"}


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"success": False, "error": "Usage: python vision_worker.py <model_path>"}))
        sys.exit(1)

    model_path = sys.argv[1]

    # Eager-load model so first client request is fast too
    try:
        _load_model(model_path)
        print(json.dumps({"ready": True, "modelLoaded": True}), flush=True)
    except ImportError:
        print(json.dumps({"ready": True, "modelLoaded": False, "mock": True}), flush=True)
    except Exception as e:
        print(json.dumps({"ready": False, "error": str(e)}), flush=True)
        sys.exit(1)

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
            result = _handle_request(req, model_path)
        except Exception as e:
            result = {"success": False, "error": str(e)}
        print(json.dumps(result), flush=True)


if __name__ == "__main__":
    main()
