from flask import Flask, request, jsonify, send_file
from llm_processor import analyze_parking_image
from datetime import datetime
import os
import csv
import math

app = Flask(__name__)

# Global: remember last uploaded image path
LAST_IMAGE_PATH = None

# CSV file for historical spot records
HISTORY_CSV = "history.csv"

# In-memory "current snapshot" of the latest analysis per camera
# {
#   "cam-001": {
#       "timestamp": "...ISO...",
#       "spots": [
#           {
#               "spot_index": 0,
#               "status": "empty",
#               "lat": None,
#               "lng": None,
#           },
#           ...
#       ]
#   },
#   ...
# }
CURRENT_SPOTS = {}

# Hardcoded coordinates for each (camera_id, spot_index).
# Dummy values for now; later you can calibrate these to real GPS coords.
SPOT_COORDS = {
    ("cam-001", 0): (40.8080, -73.9620),  # e.g. "spot-101"
    ("cam-001", 1): (40.8078, -73.9624),  # e.g. "spot-102"
    # Add more as you add more cameras/spots
}

def haversine_distance_m(lat1, lng1, lat2, lng2):
    """
    Rough distance between two lat/lng points in meters.
    Good enough for campus-scale distances.
    """
    if None in (lat1, lng1, lat2, lng2):
        return None

    R = 6371000.0  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lng2 - lng1)

    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c


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
    user_lat = request.args.get("lat", type=float)
    user_lng = request.args.get("lng", type=float)
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
    if CURRENT_SPOTS:
        for camera_id, snapshot in CURRENT_SPOTS.items():
            camera_ts = snapshot.get("timestamp")
            for rec in snapshot.get("spots", []):
                spot_index = rec.get("spot_index")
                status = rec.get("status")
                lat = rec.get("lat")
                lng = rec.get("lng")

                distance_m = None
                if (
			user_lat is not None and user_lng is not None and 
			lat is not None and lng is not None
		):
                    distance_m = haversine_distance_m(user_lat, user_lng, lat, lng)
		if radius is not None and distance_m is not None and distance_m > radius:
			continue

                spot = {
                    "spotID": f"{camera_id}-spot-{spot_index}",
                    "lat": lat,
                    "lng": lng,
                    "status": status,
                    "sourceCameraID": camera_id,
                    "lastUpdated": camera_ts,
                    "distanceMeters": distance_m,
                }
                spots.append(spot)

    response = {
        "timestamp": now_iso,
        "query": {
            "lat": user_lat,
            "lng": user_lng,
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

    now_iso = datetime.utcnow().isoformat() + "Z"

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

    # --- Step: Call LLM to analyze the image ---
    try:
        llm_result = analyze_parking_image(filename)
        print("[LLM Result]", llm_result)
    except Exception as e:
        llm_result = {"error": str(e)}
        print("[LLM ERROR]", e)

    if "error" not in llm_result:
        update_spot_storage(camera_id, llm_result, now_iso)

    return jsonify({
        "status": "ok",
        "camera_id": camera_id,
        "size_bytes": size,
        "file": filename,
        "timestamp": now_iso,
        "llm" : llm_result,
    }), 200

# Helper function to update storage
def update_spot_storage(camera_id: str, llm_result: dict, timestamp_iso: str):
    """
    Update the in-memory CURRENT_SPOTS and append to HISTORY_CSV.
    For now, lat/lng are left as None placeholders until we wire in real coordinates.
    """
    global CURRENT_SPOTS

    spots = llm_result.get("spots", []) or []

    # Build records with placeholder coordinates for now
    records = []
    for spot in spots:
        spot_index = spot.get("spot_index")
        status = spot.get("status")
	
	lat, lng = SPOT_COORDS.get((camera_id, spot_index), (None, None))

        record = {
            "timestamp": timestamp_iso,
            "camera_id": camera_id,
            "spot_index": spot_index,
            "status": status,
            "lat": lat,   # TODO: fill from a camera/spot -> GPS map later
            "lng": lng,
        }
        records.append(record)

    # Update in-memory snapshot for this camera
    CURRENT_SPOTS[camera_id] = {
        "timestamp": timestamp_iso,
        "spots": records,
    }

    # Append to CSV history
    if not records:
        return  # nothing to log

    file_exists = os.path.exists(HISTORY_CSV)
    fieldnames = ["timestamp", "camera_id", "spot_index", "status", "lat", "lng"]

    with open(HISTORY_CSV, mode="a", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        if not file_exists:
            writer.writeheader()
        writer.writerows(records)


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

