"""
HSV-based red LED detection for charger status indicators.
Invoked from Node: python opencv_red_detect.py <image_path>
"""
import sys
import json



def _analyze_hsv_region(hsv, min_sat=120, min_val=100):  # was min_sat=80, min_val=60
    import cv2
    import numpy as np

    lower_red1 = np.array([0,  min_sat, min_val])
    upper_red1 = np.array([8,  255, 255])   # was 12 — excludes the hue=8-12 false positives
    lower_red2 = np.array([172, min_sat, min_val])  # was 168
    upper_red2 = np.array([180, 255, 255])
    
    mask1 = cv2.inRange(hsv, lower_red1, upper_red1)
    mask2 = cv2.inRange(hsv, lower_red2, upper_red2)
    mask = cv2.bitwise_or(mask1, mask2)

    kernel = np.ones((3, 3), np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)

    red_pixels = int(cv2.countNonZero(mask))
    region_pixels = max(hsv.shape[0] * hsv.shape[1], 1)
    ratio = red_pixels / region_pixels

    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    max_area = max((cv2.contourArea(c) for c in contours), default=0.0)
    return ratio, max_area


def _detect_red_opencv(image_path):
    import cv2

    img = cv2.imread(image_path)
    if img is None:
        return {"success": False, "error": "Could not read image", "lightDetected": False, "lightColor": "OFF"}

    h, w = img.shape[:2]
    hsv_full = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

    regions = [
        (int(h * 0.10), int(h * 0.60), int(w * 0.20), int(w * 0.80)),
        (0, h, 0, w),
    ]

    best_ratio = 0.0
    best_area = 0.0
    for y0, y1, x0, x1 in regions:
        roi_hsv = hsv_full[y0:y1, x0:x1]
        ratio, max_area = _analyze_hsv_region(roi_hsv)
        best_ratio = max(best_ratio, ratio)
        best_area = max(best_area, max_area)
        if ratio > 0.03 or max_area >= 200:  # was 0.0008 / 35 — much stricter early exit
            break

    # Require meaningful red presence — not just noise
    light_detected = best_ratio > 0.02 or best_area >= 150
    # was: best_ratio > 0.0005 or best_area >= 30

    confidence = min(0.99, max(best_ratio * 10.0, best_area / 1000.0))
    # was: ratio * 120 — that inflated confidence from tiny ratios

    return {
        "success": True,
        "lightDetected": bool(light_detected),
        "lightColor": "RED" if light_detected else "OFF",
        "confidence": round(float(confidence), 4),
        "redPixelRatio": round(float(best_ratio), 6),
        "maxBlobArea": round(float(best_area), 2),
        "method": "opencv_hsv",
    }


def _detect_red_pil(image_path):
    """Fallback when opencv-python is not installed."""
    from PIL import Image

    img = Image.open(image_path).convert("RGB")
    w, h = img.size
    x0, x1 = int(w * 0.25), int(w * 0.75)
    y0, y1 = int(h * 0.15), int(h * 0.55)
    roi = img.crop((x0, y0, x1, y1))
    pixels = list(roi.getdata())
    step = max(len(pixels) // 8000, 1)
    red_hits = 0
    sampled = 0
    for i in range(0, len(pixels), step):
        r, g, b = pixels[i]
        sampled += 1
        if r >= 140 and r >= g * 1.35 and r >= b * 1.35 and (r - g) >= 40:
            red_hits += 1
    ratio = red_hits / max(sampled, 1)
    light_detected = ratio > 0.02
    return {
        "success": True,
        "lightDetected": light_detected,
        "lightColor": "RED" if light_detected else "OFF",
        "confidence": round(min(0.95, ratio * 3.0), 4),
        "redPixelRatio": round(ratio, 6),
        "method": "pil_rgb_fallback",
    }


def detect_red(image_path):
    try:
        return _detect_red_opencv(image_path)
    except ImportError:
        try:
            return _detect_red_pil(image_path)
        except Exception as e:
            return {
                "success": False,
                "error": f"opencv-python not installed and PIL fallback failed: {e}",
                "lightDetected": False,
                "lightColor": "OFF",
            }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "lightDetected": False,
            "lightColor": "OFF",
        }


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"success": False, "error": "Usage: python opencv_red_detect.py <image_path>"}))
        sys.exit(1)
    print(json.dumps(detect_red(sys.argv[1])))
