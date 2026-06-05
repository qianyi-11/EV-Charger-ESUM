"""
HSV-based red LED detection for charger status indicators.
Invoked from Node: python opencv_red_detect.py <image_path> [x1 y1 x2 y2]

When a YOLO charger bounding box is supplied, only the upper-center panel
region inside that box is analyzed for a compact, bright red LED blob.
"""
import sys
import json


def _charger_led_regions(x1, y1, x2, y2):
    """Candidate LED bands inside the YOLO charger box (position varies by model)."""
    width = max(x2 - x1, 1)
    height = max(y2 - y1, 1)
    return [
        (
            int(x1 + width * 0.08),
            int(y1 + height * 0.02),
            int(x1 + width * 0.92),
            int(y1 + height * 0.55),
        ),
        (
            int(x1 + width * 0.15),
            int(y1 + height * 0.08),
            int(x1 + width * 0.85),
            int(y1 + height * 0.70),
        ),
    ]


def _analyze_led_blobs(hsv, min_sat=90, min_val=110):
    """Look for a small, bright, compact red blob typical of an LED indicator."""
    import cv2
    import numpy as np

    lower_red1 = np.array([0, min_sat, min_val])
    upper_red1 = np.array([15, 255, 255])
    lower_red2 = np.array([165, min_sat, min_val])
    upper_red2 = np.array([180, 255, 255])

    mask1 = cv2.inRange(hsv, lower_red1, upper_red1)
    mask2 = cv2.inRange(hsv, lower_red2, upper_red2)
    mask = cv2.bitwise_or(mask1, mask2)

    kernel = np.ones((3, 3), np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)

    roi_h, roi_w = hsv.shape[:2]
    region_pixels = max(roi_h * roi_w, 1)
    red_pixels = int(cv2.countNonZero(mask))
    ratio = red_pixels / region_pixels

    # LEDs stay tiny even when the charger ROI is large — do not scale minimum area up.
    min_blob_area = 6.0
    max_blob_area = max(250.0, region_pixels * 0.02)
    max_led_dim = max(18.0, min(roi_w, roi_h) * 0.25)

    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    best_score = 0.0
    best_area = 0.0

    for contour in contours:
        area = float(cv2.contourArea(contour))
        if area < min_blob_area or area > max_blob_area:
            continue

        x, y, w, h = cv2.boundingRect(contour)
        if w <= 0 or h <= 0:
            continue
        if max(w, h) > max_led_dim:
            continue

        compactness = area / float(w * h)
        if compactness < 0.18:
            continue

        blob_mask = np.zeros(mask.shape, dtype=np.uint8)
        cv2.drawContours(blob_mask, [contour], -1, 255, -1)
        mean_val = float(cv2.mean(hsv[:, :, 2], mask=blob_mask)[0])
        mean_sat = float(cv2.mean(hsv[:, :, 1], mask=blob_mask)[0])
        if mean_val < 120 or mean_sat < 80:
            continue

        score = min(
            0.99,
            (mean_val / 255.0) * 0.45
            + compactness * 0.25
            + min(area / 120.0, 0.25)
            + min(ratio * 4.0, 0.15),
        )
        if score > best_score:
            best_score = score
            best_area = area

    light_detected = best_score >= 0.28
    return light_detected, best_score, ratio, best_area


def _rgb_red_ratio(bgr):
    """Mobile JPEGs often wash out HSV — use a simple RGB dominance check too."""
    import numpy as np

    if bgr.size == 0:
        return 0.0, 0.0

    step = max((bgr.shape[0] * bgr.shape[1]) // 12000, 1)
    sampled = bgr[::step, ::step]
    r = sampled[:, :, 2].astype(np.int16)
    g = sampled[:, :, 1].astype(np.int16)
    b = sampled[:, :, 0].astype(np.int16)

    bright_red = (r >= 135) & (r > g * 1.28) & (r > b * 1.28) & ((r - g) >= 35)
    vivid_red = (r >= 165) & (r > g * 1.45) & (r > b * 1.45) & ((r - g) >= 50)

    total = max(int(bright_red.size), 1)
    bright_ratio = float(np.count_nonzero(bright_red)) / total
    vivid_ratio = float(np.count_nonzero(vivid_red)) / total
    return bright_ratio, vivid_ratio


def _scan_region(hsv_roi, bgr_roi):
    blob_detected, blob_score, ratio, max_area = _analyze_led_blobs(hsv_roi)
    bright_ratio, vivid_ratio = _rgb_red_ratio(bgr_roi)

    rgb_detected = vivid_ratio >= 0.004 or (bright_ratio >= 0.012 and vivid_ratio >= 0.0015)
    rgb_score = min(0.95, vivid_ratio * 18.0 + bright_ratio * 4.0)

    detected = blob_detected or rgb_detected
    confidence = max(blob_score, rgb_score)
    return detected, confidence, ratio, max_area, bright_ratio, vivid_ratio


def _detect_red_opencv(image_path, charger_box=None):
    import cv2

    img = cv2.imread(image_path)
    if img is None:
        return {"success": False, "error": "Could not read image", "lightDetected": False, "lightColor": "OFF"}

    h, w = img.shape[:2]
    hsv_full = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

    best = {
        "lightDetected": False,
        "confidence": 0.0,
        "redPixelRatio": 0.0,
        "maxBlobArea": 0.0,
        "brightRedRatio": 0.0,
        "vividRedRatio": 0.0,
        "roi": "fallback_center_crop",
    }

    if charger_box and len(charger_box) == 4:
        x1, y1, x2, y2 = [int(round(v)) for v in charger_box]
        x1 = max(0, min(x1, w - 1))
        y1 = max(0, min(y1, h - 1))
        x2 = max(x1 + 1, min(x2, w))
        y2 = max(y1 + 1, min(y2, h))
        regions = _charger_led_regions(x1, y1, x2, y2)
    else:
        regions = [
            (int(w * 0.15), int(h * 0.08), int(w * 0.85), int(h * 0.65)),
        ]

    for idx, (rx1, ry1, rx2, ry2) in enumerate(regions):
        rx1 = max(0, min(rx1, w - 1))
        ry1 = max(0, min(ry1, h - 1))
        rx2 = max(rx1 + 1, min(rx2, w))
        ry2 = max(ry1 + 1, min(ry2, h))
        roi_bgr = img[ry1:ry2, rx1:rx2]
        roi_hsv = hsv_full[ry1:ry2, rx1:rx2]
        if roi_hsv.size == 0:
            continue

        detected, confidence, ratio, max_area, bright_ratio, vivid_ratio = _scan_region(
            roi_hsv, roi_bgr
        )
        if confidence > best["confidence"]:
            best = {
                "lightDetected": detected,
                "confidence": confidence,
                "redPixelRatio": ratio,
                "maxBlobArea": max_area,
                "brightRedRatio": bright_ratio,
                "vividRedRatio": vivid_ratio,
                "roi": f"yolo_led_band_{idx}",
            }

    return {
        "success": True,
        "lightDetected": bool(best["lightDetected"]),
        "lightColor": "RED" if best["lightDetected"] else "OFF",
        "confidence": round(float(best["confidence"]), 4),
        "redPixelRatio": round(float(best["redPixelRatio"]), 6),
        "maxBlobArea": round(float(best["maxBlobArea"]), 2),
        "brightRedRatio": round(float(best["brightRedRatio"]), 6),
        "vividRedRatio": round(float(best["vividRedRatio"]), 6),
        "method": "opencv_hsv_rgb",
        "roi": best["roi"],
    }


def _detect_red_pil(image_path, charger_box=None):
    """Fallback when opencv-python is not installed."""
    from PIL import Image

    img = Image.open(image_path).convert("RGB")
    w, h = img.size

    if charger_box and len(charger_box) == 4:
        cx1, cy1, cx2, cy2 = [int(round(v)) for v in charger_box]
        cx1 = max(0, min(cx1, w - 1))
        cy1 = max(0, min(cy1, h - 1))
        cx2 = max(cx1 + 1, min(cx2, w))
        cy2 = max(cy1 + 1, min(cy2, h))
        c_w = max(cx2 - cx1, 1)
        c_h = max(cy2 - cy1, 1)
        x0 = cx1 + int(c_w * 0.25)
        x1 = cx1 + int(c_w * 0.75)
        y0 = cy1 + int(c_h * 0.05)
        y1 = cy1 + int(c_h * 0.45)
    else:
        x0, x1 = int(w * 0.30), int(w * 0.70)
        y0, y1 = int(h * 0.08), int(h * 0.45)

    roi = img.crop((x0, y0, x1, y1))
    pixels = list(roi.getdata())
    step = max(len(pixels) // 8000, 1)
    red_hits = 0
    bright_red_hits = 0
    sampled = 0
    for i in range(0, len(pixels), step):
        r, g, b = pixels[i]
        sampled += 1
        if r >= 160 and r >= g * 1.5 and r >= b * 1.5 and (r - g) >= 50:
            red_hits += 1
            if r >= 190 and (r - g) >= 70:
                bright_red_hits += 1
    ratio = red_hits / max(sampled, 1)
    bright_ratio = bright_red_hits / max(sampled, 1)
    light_detected = bright_ratio > 0.008 and ratio > 0.015
    return {
        "success": True,
        "lightDetected": light_detected,
        "lightColor": "RED" if light_detected else "OFF",
        "confidence": round(min(0.95, bright_ratio * 8.0), 4),
        "redPixelRatio": round(ratio, 6),
        "method": "pil_rgb_fallback",
    }


def detect_red(image_path, charger_box=None):
    try:
        return _detect_red_opencv(image_path, charger_box)
    except ImportError:
        try:
            return _detect_red_pil(image_path, charger_box)
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
        print(json.dumps({"success": False, "error": "Usage: python opencv_red_detect.py <image_path> [x1 y1 x2 y2]"}))
        sys.exit(1)

    box = None
    if len(sys.argv) >= 6:
        try:
            box = [float(sys.argv[i]) for i in range(2, 6)]
        except ValueError:
            box = None

    print(json.dumps(detect_red(sys.argv[1], box)))
