#!/usr/bin/env python3
"""
Blinking LED Detector - Analyzes video frames for red light blinking patterns
Uses OpenCV to extract frames and detect red light intensity changes
"""

import cv2
import numpy as np
import json
import sys
from pathlib import Path

def analyze_video_for_blinking(video_path, frame_skip=1):
    """
    Analyzes video for red light blinking detection - optimized for FAST blinking
    
    Args:
        video_path: Path to video file
        frame_skip: Process every Nth frame (1 = every frame for fast blinks)
    
    Returns:
        dict with blink_count, success, confidence, etc.
    """
    
    try:
        if not Path(video_path).exists():
            return {
                "success": False,
                "blink_count": 0,
                "confidence": 0.0,
                "error": f"Video file not found: {video_path}"
            }
        
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            return {
                "success": False,
                "blink_count": 0,
                "confidence": 0.0,
                "error": "Failed to open video file"
            }
        
        # Get video properties
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        print(f"[Python Analyzer] Video: {total_frames} frames, {fps} fps, {width}x{height}", file=sys.stderr)
        print(f"[Python Analyzer] Processing every {frame_skip} frame(s)...", file=sys.stderr)
        
        # Extract red light intensity from frames using BGR
        red_intensities = []
        frame_count = 0
        processed_frame_count = 0
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            
            frame_count += 1
            
            # Skip frames for efficiency (1 = process every frame for fast blinks)
            if frame_count % frame_skip != 0:
                continue
            
            processed_frame_count += 1
            
            # Get center region of frame for better detection
            h, w = frame.shape[:2]
            center_x, center_y = w // 2, h // 2
            region_size = 200  # Larger region for fast blinking
            
            x1 = max(0, center_x - region_size // 2)
            x2 = min(w, center_x + region_size // 2)
            y1 = max(0, center_y - region_size // 2)
            y2 = min(h, center_y + region_size // 2)
            
            roi = frame[y1:y2, x1:x2]
            
            # Extract BGR channels
            b, g, r = cv2.split(roi)
            
            # More lenient red check: r > 80 && r > g * 1.1 && r > b * 1.1
            red_mask = (r > 80) & (r > g.astype(float) * 1.1) & (r > b.astype(float) * 1.1)
            
            # Calculate percentage of red pixels
            red_percentage = np.sum(red_mask) / red_mask.size
            
            # Use red percentage as intensity (0-1)
            red_intensities.append(red_percentage)
            
            # Frame-by-frame debug: show if red light detected
            red_detected = "YES" if red_percentage > 0.001 else "NO"
            if processed_frame_count <= 50 or processed_frame_count % 10 == 0:  # Print first 50 frames + every 10th
                print(f"[Python Analyzer] Frame {processed_frame_count}: RED={red_detected:3} | Intensity: {red_percentage:.6f}", file=sys.stderr)
        
        cap.release()
        
        if not red_intensities:
            return {
                "success": False,
                "blink_count": 0,
                "confidence": 0.0,
                "error": "No frames extracted from video"
            }
        
        print(f"[Python Analyzer] Total frames analyzed: {len(red_intensities)}", file=sys.stderr)
        print(f"[Python Analyzer] Intensity range: {min(red_intensities):.4f} - {max(red_intensities):.4f}", file=sys.stderr)
        
        # Detect blinking by finding rapid changes
        blink_count = detect_blinks_from_intensity(red_intensities, threshold=0.02)
        
        # Calculate confidence based on signal clarity
        intensity_array = np.array(red_intensities)
        signal_variation = np.std(intensity_array)
        confidence = min(1.0, max(0.0, signal_variation * 5))  # Higher amplification
        
        # Determine if detection was successful
        success = len(red_intensities) > 20  # Need enough frames
        
        return {
            "success": success,
            "blink_count": blink_count,
            "confidence": confidence,
            "frames_analyzed": len(red_intensities),
            "total_frames": total_frames,
            "signal_variation": float(signal_variation),
            "max_intensity": float(max(red_intensities)),
            "min_intensity": float(min(red_intensities))
        }
        
    except Exception as e:
        return {
            "success": False,
            "blink_count": 0,
            "confidence": 0.0,
            "error": str(e)
        }

def detect_blinks_from_intensity(intensities, threshold=0.02):
    """
    Detects blinks by finding transitions in red light intensity
    Optimized for FAST blinking patterns
    
    Args:
        intensities: List of red intensity values [0-1]
        threshold: Minimum intensity to consider as "ON" (very low for fast blinks)
    
    Returns:
        Number of detected blinks
    """
    
    if len(intensities) < 2:
        return 0
    
    # Light smoothing (window 3 instead of 5) to preserve fast transitions
    smoothed = smooth_signal(intensities, window_size=3)
    
    # Detect transitions (ON->OFF or OFF->ON)
    blink_count = 0
    prev_state = None
    state_changes = []
    
    for i, intensity in enumerate(smoothed):
        # Determine current state
        if intensity > threshold:
            current_state = 'on'
        else:
            current_state = 'off'
        
        # Detect state transition
        if prev_state is not None and prev_state != current_state:
            state_changes.append((i, prev_state, current_state))
        
        prev_state = current_state
    
    # Count transitions from OFF->ON as blinks
    blink_count = sum(1 for _, prev, curr in state_changes if prev == 'off' and curr == 'on')
    
    print(f"[Python Analyzer] Smoothed intensity range: {min(smoothed):.5f} - {max(smoothed):.5f}", file=sys.stderr)
    print(f"[Python Analyzer] Threshold: {threshold:.5f}", file=sys.stderr)
    print(f"[Python Analyzer] State changes detected: {len(state_changes)}", file=sys.stderr)
    print(f"[Python Analyzer] Blinks (OFF->ON transitions): {blink_count}", file=sys.stderr)
    
    # Print first 30 transitions for debugging
    for idx, prev, curr in state_changes[:30]:
        print(f"[Python Analyzer]   Frame {idx}: {prev:3} -> {curr:3}", file=sys.stderr)
    
    return blink_count

def smooth_signal(signal, window_size=3):
    """Apply moving average smoothing - lightweight for fast transitions"""
    if window_size < 1:
        return signal
    
    smoothed = []
    half_window = window_size // 2
    
    for i in range(len(signal)):
        start = max(0, i - half_window)
        end = min(len(signal), i + half_window + 1)
        smoothed.append(np.mean(signal[start:end]))
    
    return smoothed

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({
            "success": False,
            "blink_count": 0,
            "confidence": 0.0,
            "error": "Video path required"
        }))
        sys.exit(1)
    
    video_path = sys.argv[1]
    result = analyze_video_for_blinking(video_path)
    
    # Output as JSON to stdout
    print(json.dumps(result))
