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
        
        intensity_array = np.array(red_intensities)
        signal_variation = float(np.std(intensity_array))
        mean_intensity = float(np.mean(intensity_array))
        max_intensity = float(np.max(intensity_array))

        # Detect blinking — split into sequences at long pauses, take highest count
        effective_fps = (fps / frame_skip) if fps and fps > 0 else (30.0 / frame_skip)
        blink_analysis = detect_blinks_from_intensity(
            red_intensities,
            threshold=0.02,
            effective_fps=effective_fps,
            break_threshold_sec=2.0,
        )
        blink_count = blink_analysis["blink_count"]
        total_blink_count = blink_analysis["total_blink_count"]
        sequences_detected = blink_analysis["sequences_detected"]

        # Classify pattern: blinking vs steady solid red vs no red signal
        red_present_threshold = 0.012
        solid_red_variation_threshold = 0.01

        if (
            blink_count > 0
            and blink_count <= 2
            and mean_intensity >= red_present_threshold
            and signal_variation <= solid_red_variation_threshold
        ):
            # Camera settle or aim-in often creates 1–2 false OFF→ON edges on steady red.
            blink_count = 0

        is_solid_red = (
            blink_count == 0
            and mean_intensity >= red_present_threshold
            and signal_variation <= solid_red_variation_threshold
        )
        has_red_signal = max_intensity >= red_present_threshold

        if is_solid_red:
            pattern = "solid_red"
            confidence = min(0.95, 0.78 + mean_intensity * 3)
        elif blink_count > 0:
            pattern = "blinking"
            confidence = min(1.0, max(0.55, signal_variation * 5))
        elif has_red_signal:
            # Red visible but did not meet solid-red stability criteria
            pattern = "solid_red"
            confidence = min(0.9, 0.65 + mean_intensity * 2)
            blink_count = 0
        else:
            pattern = "no_red"
            confidence = 0.0

        success = len(red_intensities) > 20 and pattern in ("solid_red", "blinking")

        print(
            f"[Python Analyzer] Pattern={pattern} blinks={blink_count} "
            f"(total={total_blink_count}, sequences={sequences_detected}) "
            f"mean={mean_intensity:.5f} std={signal_variation:.5f}",
            file=sys.stderr,
        )
        
        return {
            "success": success,
            "blink_count": blink_count,
            "total_blink_count": total_blink_count,
            "sequences_detected": sequences_detected,
            "pattern": pattern,
            "confidence": confidence,
            "frames_analyzed": len(red_intensities),
            "total_frames": total_frames,
            "signal_variation": signal_variation,
            "mean_intensity": mean_intensity,
            "max_intensity": max_intensity,
            "min_intensity": float(min(red_intensities))
        }
        
    except Exception as e:
        return {
            "success": False,
            "blink_count": 0,
            "confidence": 0.0,
            "error": str(e)
        }

def detect_blink_events(smoothed, threshold=0.02):
    """Return frame indices of each OFF->ON transition (one per blink)."""
    events = []
    prev_state = None

    for i, intensity in enumerate(smoothed):
        current_state = 'on' if intensity > threshold else 'off'
        if prev_state == 'off' and current_state == 'on':
            events.append(i)
        prev_state = current_state

    return events


def split_blink_sequences(blink_events, effective_fps, break_threshold_sec=2.0):
    """
    Group blink events into sequences. A gap longer than break_threshold_sec
    between consecutive blinks starts a new sequence (e.g. 3 blinks, pause,
    7 blinks, pause, 2 blinks → three separate groups).
    """
    if not blink_events:
        return []

    sequences = [[blink_events[0]]]

    for i in range(1, len(blink_events)):
        gap_sec = (blink_events[i] - blink_events[i - 1]) / max(effective_fps, 1.0)
        if gap_sec >= break_threshold_sec:
            sequences.append([blink_events[i]])
        else:
            sequences[-1].append(blink_events[i])

    return sequences


def detect_blinks_from_intensity(
    intensities,
    threshold=0.02,
    effective_fps=30.0,
    break_threshold_sec=2.0,
):
    """
    Detects blinks split by long pauses and returns the highest sequence count.

    EV chargers may show partial or repeated fault bursts in one recording
    (e.g. 3 + break + 7 + break + 2). The longest burst is the fault code.
    """
    if len(intensities) < 2:
        return {
            "blink_count": 0,
            "total_blink_count": 0,
            "sequences_detected": 0,
            "selected_sequence_index": -1,
            "blink_events": [],
            "sequences": [],
        }

    smoothed = smooth_signal(intensities, window_size=3)
    blink_events = detect_blink_events(smoothed, threshold)
    sequences = split_blink_sequences(blink_events, effective_fps, break_threshold_sec)

    sequence_counts = [len(seq) for seq in sequences]
    selected_sequence_count = max(sequence_counts) if sequence_counts else 0
    selected_sequence_index = (
        sequence_counts.index(selected_sequence_count) if sequence_counts else -1
    )
    total_blink_count = len(blink_events)

    print(f"[Python Analyzer] Smoothed intensity range: {min(smoothed):.5f} - {max(smoothed):.5f}", file=sys.stderr)
    print(f"[Python Analyzer] Threshold: {threshold:.5f}", file=sys.stderr)
    print(f"[Python Analyzer] Effective FPS: {effective_fps:.2f}", file=sys.stderr)
    print(f"[Python Analyzer] Break threshold: {break_threshold_sec:.1f}s", file=sys.stderr)
    print(f"[Python Analyzer] Total OFF->ON events: {total_blink_count}", file=sys.stderr)
    print(f"[Python Analyzer] Sequences detected: {len(sequences)}", file=sys.stderr)
    print(
        f"[Python Analyzer] Sequence counts: {sequence_counts} → "
        f"selected {selected_sequence_count} blinks (sequence #{selected_sequence_index + 1})",
        file=sys.stderr,
    )

    for seq_idx, seq in enumerate(sequences):
        marker = " ← selected" if seq_idx == selected_sequence_index else ""
        print(
            f"[Python Analyzer]   Sequence #{seq_idx + 1}: {len(seq)} blinks{marker}",
            file=sys.stderr,
        )
        if seq_idx > 0:
            gap_sec = (seq[0] - sequences[seq_idx - 1][-1]) / max(effective_fps, 1.0)
            print(
                f"[Python Analyzer]     (after {gap_sec:.2f}s break from previous sequence)",
                file=sys.stderr,
            )

    for idx, frame in enumerate(blink_events[:30]):
        print(f"[Python Analyzer]   Blink {idx + 1} at processed frame {frame}", file=sys.stderr)

    return {
        "blink_count": selected_sequence_count,
        "total_blink_count": total_blink_count,
        "sequences_detected": len(sequences),
        "selected_sequence_index": selected_sequence_index,
        "sequence_counts": sequence_counts,
        "blink_events": blink_events,
        "sequences": sequences,
    }

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
