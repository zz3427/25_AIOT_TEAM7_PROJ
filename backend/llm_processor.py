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
        "spots": [
            {
                "spot_index": 0,
                "status": "empty" or "occupied"
            },
            ...
        ],
        "notes": "Model's brief explanation"
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
        "You analyze fixed-view parking lot images. "
        "Identify each clearly marked parking spot and whether it is EMPTY or OCCUPIED. "
        "Respond as a STRICT JSON object only, with no extra text."
    )

    user_text_prompt = (
        "Look at this parking lot image and return JSON in exactly this format:\n"
        "{\n"
        "  \"total_spots\": <integer total number of visible parking spots>,\n"
        "  \"empty_spots\": <integer number of empty spots>,\n"
        "}\n"
        "Do not include any other fields or explanation. "
        "If the image is unusable, return:\n"
        "{ \"total_spots\": 0, \"empty_spots\": 0}"
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

    return data

