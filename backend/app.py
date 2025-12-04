from flask import Flask, request, jsonify, send_file
from datetime import datetime
import os

app = Flask(__name__)

# Global: remember last uploaded image path
LAST_IMAGE_PATH = None

# Health check / root
@app.route("/")
def root():
    return "Team7 Parking backend is running 👋", 200

# Current empty spots (for iOS)
@app.route("/api/spots/current", methods=["GET"])
def api_spots_current():
    """
    Returns dummy current spots for now.
    Shape matches your iOS Models.swift:

    struct CurrentSpotsResponse {
        let timestamp: String?
        let query: QueryInfo?
        let spots: [ParkingSpot]
    }

    struct ParkingSpot {
        let spotID: String
        let lat: Double
        let lng: Double
        let status: String
        let sourceCameraID: String?
        let lastUpdated: Date?
    }
    """

    # Optional query params from app (can be nil on first version)
    lat = request.args.get("lat", type=float)
    lng = request.args.get("lng", type=float)
    radius = request.args.get("radius", type=int)

    # For now, just return a dummy list
    now_iso = datetime.utcnow().isoformat() + "Z"

    spots = [
        {
            "spotID": "spot-101",
            "lat": 40.8080,
            "lng": -73.9620,
            "status": "empty",
            "sourceCameraID": "cam-001",
            "lastUpdated": now_iso,
        },
        {
            "spotID": "spot-102",
            "lat": 40.8078,
            "lng": -73.9624,
            "status": "occupied",
            "sourceCameraID": "cam-001",
            "lastUpdated": now_iso,
        },
    ]

    response = {
        "timestamp": now_iso,
        "query": {
            "lat": lat,
            "lng": lng,
            "radius": radius,
        },
        "spots": spots,
    }

    return jsonify(response), 200


# -----------------------------
# Camera upload (from ESP32-CAM)
# -----------------------------
@app.route("/api/camera/upload", methods=["POST"])
def camera_upload():
    """
    ESP32-CAM should POST raw JPEG bytes to this endpoint.

    Example URL the ESP32 uses:
    http://<LAPTOP_IP>:8080/api/camera/upload?camera_id=cam-001
    Content-Type: image/jpeg
    Body: <raw JPEG bytes>
    """
    global LAST_IMAGE_PATH

    camera_id = request.args.get("camera_id", "unknown")

    img_bytes = request.data or b""
    size = len(img_bytes)
    print(f"[camera_upload] Received image from {camera_id}, size={size} bytes")

    if not img_bytes:
        return jsonify({"error": "no data"}), 400

    # Save image to disk
    os.makedirs("captures", exist_ok=True)
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    filename = os.path.join("captures", f"{camera_id}_{timestamp}.jpg")

    with open(filename, "wb") as f:
        f.write(img_bytes)

    print(f"[camera_upload] Saved image to {filename}")

    # Remember this as the "latest" image
    LAST_IMAGE_PATH = filename

    return jsonify({
        "status": "ok",
        "camera_id": camera_id,
        "size_bytes": size,
        "file": filename,
    }), 200


# -----------------------------
# Show latest camera frame as raw JPEG
# -----------------------------
@app.route("/camera/latest", methods=["GET"])
def camera_latest():
    """
    Returns the latest uploaded image as image/jpeg,
    so opening this URL in a browser shows the photo.
    """
    global LAST_IMAGE_PATH

    if not LAST_IMAGE_PATH or not os.path.exists(LAST_IMAGE_PATH):
        return "No image received yet.", 404

    return send_file(LAST_IMAGE_PATH, mimetype="image/jpeg")


# -----------------------------
# Simple HTML viewer
# -----------------------------
@app.route("/camera/view", methods=["GET"])
def camera_view():
    """
    Simple HTML page that shows the <img> for /camera/latest.
    """
    return """
    <html>
      <body style="background:#111; color:#eee; font-family: -apple-system, system-ui, sans-serif;">
        <h2>Latest camera frame</h2>
        <p>Refresh this page after the ESP32 uploads a new image.</p>
        <img src="/camera/latest" style="max-width: 100%; height: auto; border: 1px solid #444;" />
      </body>
    </html>
    """, 200


# -----------------------------
# Main entry
# -----------------------------
if __name__ == "__main__":
    # Run on all interfaces so iPhone & ESP32 on same Wi-Fi can reach it.
    app.run(host="0.0.0.0", port=8080, debug=True)

