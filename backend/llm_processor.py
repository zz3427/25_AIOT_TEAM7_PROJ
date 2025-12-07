# backend/llm_processor.py

import base64
import json
from pathlib import Path
from typing import Dict, Any

from dotenv import load_dotenv
load_dotenv()

from openai import OpenAI

# Assumes OPENAI_API_KEY is set in your environment
# e.g. export OPENAI_API_KEY="sk-..."
client = OpenAI()

NUM_SPOTS = 6

def _encode_image_to_data_url(image_path: Path) -> str:
    """
    Read image bytes and return a data URL string suitable for the OpenAI image_url field.
    """
    with image_path.open("rb") as f:
        img_bytes = f.read()

    b64 = base64.b64encode(img_bytes).decode("utf-8")
    # assuming JPEG from ESP32-CAM
    return f"data:image/jpeg;base64,{b64}"


def analyze_parking_image(image_path: str) -> Dict[str, Any]:
    """
    Takes a local JPEG path, sends it to an LLM for analysis,
    and returns structured information about parking spots.

    Expected return shape (example):

    {
	"total_spots": 6,
	"empty_spots": <int>,
    }

    Coordinates (lat/lng) will be attached later by mapping
    camera_id + spot_index -> GPS in our backend.
    """

    image_path_obj = Path(image_path)

    if not image_path_obj.exists():
        raise FileNotFoundError(f"Image not found: {image_path_obj}")

    image_data_url = _encode_image_to_data_url(image_path_obj)

    # System + user prompt: keep it VERY clear we want strict JSON.
    system_prompt = (
        #"You analyze fixed-view parking lot images. "
        #"Identify each clearly marked parking spot and whether it is EMPTY or OCCUPIED. "
        #"Respond as a STRICT JSON object only, with no extra text."
        "You analyze images from a single fixed ESP32 demo camera showing a tiny parking lot drawn on white paper.\n"
        "The scene always looks like this:\n"
        "- The UPPER part of the image is the parking area on white paper, with six rectangular parking spaces in one row, "
        "separated by vertical black lines, against a wall.\n"
        "- The LOWER part of the image is a drawn road with dashed lane markings that you must ignore for parking.\n\n"
        f"For this camera, there are ALWAYS exactly {NUM_SPOTS} parking spaces in a single row, left to right.\n"
        f"Conceptually divide JUST the upper parking area into {NUM_SPOTS} equal-width vertical regions from left to right:\n"
        f"- Region 0 = leftmost space, region {NUM_SPOTS - 1} = rightmost space.\n\n"
        "For each region:\n"
        "- If any toy car or a significant part of a car is clearly inside that region, the space is OCCUPIED.\n"
        "- If the region shows only the drawn space lines and empty floor (no car), the space is EMPTY.\n"
        "- If a car overlaps two regions, treat the region where MOST of the car appears as OCCUPIED "
        "and the neighbor as EMPTY.\n\n"
        "Respond as a STRICT JSON object only, with no extra text."
    )

    user_text_prompt = (
        "Look ONLY at the parking spaces in the UPPER half of this image (above the front horizontal line) "
        "and ignore the road below.\n"
        "Using the fixed layout described above, determine whether each of the six spaces is \"empty\" or \"occupied\".\n\n"
        "Return JSON in exactly this format:\n"
        "{\n"
        "  \"total_spots\": <integer total number of visible parking spots>,\n"
        "  \"empty_spots\": <integer number of empty spots>,\n"
        "}\n\n"
        "Rules:\n"
        f"- Always set \"total_spots\" to {NUM_SPOTS}.\n"
        f"- Always return exactly {NUM_SPOTS} entries in \"spots\", one for each spot_index from 0 to {NUM_SPOTS - 1}, "
        "ordered from left to right.\n"
        "- Compute \"empty_spots\" as the count of entries whose status is \"empty\".\n"
        "- Do NOT include any other fields or explanation text.\n"
        f"If the image is completely unusable (blurry, black, or not a parking lot), still use \"total_spots\" = {NUM_SPOTS}, "
        "and set all spots to status \"occupied\" (so empty_spots = 0).\n"
    )

    # Call the OpenAI Chat Completions API with image input
    response = client.chat.completions.create(
        model="gpt-4.1-mini",  # supports vision + JSON, cheap enough for a class project
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": user_text_prompt},
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": image_data_url
                        },
                    },
                ],
            },
        ],
        max_tokens=500,
    )

    # The model was told to return a JSON object as a string
    raw_content = response.choices[0].message.content

    try:
        data = json.loads(raw_content)
    except json.JSONDecodeError:
        # Fallback: wrap raw text if model somehow returns non-JSON
        data = {
            "spots": [],
            "notes": "Failed to parse model JSON.",
        }

    if isinstance(data, dict):
        raw_spots = data.get("spots") or []

        # Collect valid statuses by index from model output
        status_by_idx = {}
        for item in raw_spots:
            if not isinstance(item, dict):
                continue
            idx = item.get("spot_index")
            status = item.get("status")
            if isinstance(idx, int) and 0 <= idx < NUM_SPOTS and status in ("empty", "occupied"):
                status_by_idx[idx] = status

        # Build canonical list: always 0..NUM_SPOTS-1
        canonical_spots = []
        for idx in range(NUM_SPOTS):
            # Default to "occupied" if model didn't give anything usable
            status = status_by_idx.get(idx, "occupied")
            canonical_spots.append(
                {
                    "spot_index": idx,
                    "status": status,
                }
            )

        data["spots"] = canonical_spots
        data["total_spots"] = NUM_SPOTS
        data["empty_spots"] = sum(1 for s in canonical_spots if s["status"] == "empty")

        # Keep raw text for debugging
        if "raw_model_text" not in data:
            data["raw_model_text"] = text

    return data

