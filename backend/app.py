from flask import Flask, request, jsonify
from datetime import datetime

# Create the Flask app
app = Flask(__name__)


# Simple home/health-check route
@app.route("/")
def root():
    return "Team7 Parking backend is running 👋", 200


# Current spots endpoint (dummy data for now)
@app.route("/api/spots/current", methods=["GET"])
def current_spots():
    spots = [
        {
            "spot_id": "spot-101",
            "lat": 40.8080,
            "lng": -73.9620,
            "status": "empty",
            "source_camera_id": "cam-001",
            "last_updated": "2025-12-01T21:30:45Z"
        }
    ]

    return jsonify({
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "spots": spots
    })


# Camera upload endpoint (just logs size for now)
@app.route("/api/camera/upload", methods=["POST"])
def camera_upload():
    camera_id = request.args.get("camera_id", "unknown")
    img_bytes = request.data or b""
    size = len(img_bytes)

    print(f"[{datetime.utcnow().isoformat()}] "
          f"Received image from {camera_id}, size={size} bytes")

    return jsonify({
        "status": "ok",
        "camera_id": camera_id,
        "received_at": datetime.utcnow().isoformat() + "Z",
        "size_bytes": size
    })


# THIS PART STARTS THE SERVER WHEN YOU RUN `python app.py`
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)

