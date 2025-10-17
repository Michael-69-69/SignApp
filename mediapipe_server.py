from flask import Flask, request, jsonify
import mediapipe as mp
import cv2
import numpy as np
import base64
from io import BytesIO

app = Flask(__name__)

# Initialize MediaPipe Hand detector
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

mp_drawing = mp.solutions.drawing_utils

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({"status": "ok"}), 200

@app.route('/detect', methods=['POST'])
def detect():
    """
    Receive base64 encoded image, run hand detection, return landmarks
    Expected JSON: {"image": "base64_string"}
    Returns: {"landmarks": [[x1,y1,z1,c1], ...], "success": true/false}
    """
    try:
        data = request.get_json()
        if not data or 'image' not in data:
            return jsonify({"error": "No image provided", "success": False}), 400

        # Decode base64 image
        image_data = base64.b64decode(data['image'])
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            return jsonify({"error": "Could not decode image", "success": False}), 400

        # Convert BGR to RGB
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        h, w, c = image_rgb.shape

        # Run MediaPipe detection
        results = hands.process(image_rgb)

        landmarks_list = []
        if results.multi_hand_landmarks:
            for hand_landmarks in results.multi_hand_landmarks:
                hand_landmarks_data = []
                for landmark in hand_landmarks.landmark:
                    # Normalize coordinates to image dimensions
                    x = landmark.x * w
                    y = landmark.y * h
                    z = landmark.z
                    confidence = landmark.visibility
                    hand_landmarks_data.append([x, y, z, confidence])
                landmarks_list.append(hand_landmarks_data)

        return jsonify({
            "landmarks": landmarks_list,
            "success": True,
            "image_size": {"width": w, "height": h},
            "num_hands": len(landmarks_list)
        }), 200

    except Exception as e:
        print(f"Error in detect: {e}")
        return jsonify({"error": str(e), "success": False}), 500

@app.route('/detect_gesture', methods=['POST'])
def detect_gesture():
    """
    Detect hand gestures (peace, thumbs up, etc.)
    Uses MediaPipe hand landmarks to classify gestures
    """
    try:
        data = request.get_json()
        if not data or 'image' not in data:
            return jsonify({"error": "No image provided", "success": False}), 400

        # Decode base64 image
        image_data = base64.b64decode(data['image'])
        nparr = np.frombuffer(image_data, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            return jsonify({"error": "Could not decode image", "success": False}), 400

        # Convert BGR to RGB
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

        # Run MediaPipe detection
        results = hands.process(image_rgb)

        gestures = []
        if results.multi_hand_landmarks:
            for hand_landmarks, handedness in zip(results.multi_hand_landmarks, results.multi_handedness):
                gesture = classify_gesture(hand_landmarks)
                hand_label = handedness.classification[0].label
                gestures.append({
                    "hand": hand_label,
                    "gesture": gesture,
                    "confidence": handedness.classification[0].score
                })

        return jsonify({
            "gestures": gestures,
            "success": True,
            "num_hands": len(gestures)
        }), 200

    except Exception as e:
        print(f"Error in detect_gesture: {e}")
        return jsonify({"error": str(e), "success": False}), 500

def classify_gesture(hand_landmarks):
    """
    Simple gesture classification based on hand landmarks
    Returns: gesture name (e.g., 'peace', 'thumbs_up', 'open_hand', 'closed_fist')
    """
    landmarks = hand_landmarks.landmark
    
    # Extract key points
    thumb_tip = landmarks[4]
    index_tip = landmarks[8]
    middle_tip = landmarks[12]
    ring_tip = landmarks[16]
    pinky_tip = landmarks[20]
    
    palm_center = landmarks[0]
    
    # Calculate distances
    def distance(p1, p2):
        return ((p1.x - p2.x)**2 + (p1.y - p2.y)**2 + (p1.z - p2.z)**2)**0.5
    
    thumb_distance = distance(thumb_tip, palm_center)
    index_distance = distance(index_tip, palm_center)
    middle_distance = distance(middle_tip, palm_center)
    ring_distance = distance(ring_tip, palm_center)
    pinky_distance = distance(pinky_tip, palm_center)
    
    # Threshold for "extended" (away from palm)
    threshold = 0.05
    
    # Count extended fingers
    extended = sum([
        index_distance > threshold,
        middle_distance > threshold,
        ring_distance > threshold,
        pinky_distance > threshold
    ])
    
    thumb_extended = thumb_distance > threshold
    
    # Classify gesture
    if extended == 0 and not thumb_extended:
        return "closed_fist"
    elif extended == 2 and index_distance > middle_distance and pinky_distance > index_distance:
        return "peace"
    elif extended == 4 and thumb_extended:
        return "open_hand"
    elif extended == 1 and index_distance > threshold and middle_distance < threshold:
        return "pointing"
    elif thumb_extended and extended == 0:
        return "thumbs_up"
    else:
        return "unknown"

if __name__ == '__main__':
    print("Starting MediaPipe server on http://localhost:5000")
    print("Health check: http://localhost:5000/health")
    print("Detection endpoint: POST http://localhost:5000/detect")
    print("Gesture endpoint: POST http://localhost:5000/detect_gesture")
    app.run(host='0.0.0.0', port=5000, debug=False)