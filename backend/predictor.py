# predictor.py
#
# New ML-based predictor that uses a trained RandomForest model
# to estimate the probability that at least one spot will be
# empty at the driver's arrival time.
#
# IMPORTANT:
# - Requires parking_forecast_model.joblib (trained by train_model_24h.py)
# - Function signatures are unchanged so the rest of the backend
#   (Flask routes, iOS app, etc.) do not need to be modified.

from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

import joblib

# Load the trained model at import time
_MODEL_PATH = Path(__file__).with_name("parking_forecast_model.joblib")
_model = joblib.load(_MODEL_PATH)


def _arrival_features(eta_minutes: float, now: datetime | None = None):
    """
    Compute model features for the *arrival time*.

    The model is trained on:
      - day_of_week: 0=Monday, ..., 6=Sunday
      - minute_of_day: 0..1439 (00:00..23:59)

    We take the current time, add eta_minutes, and convert.
    """
    if now is None:
        now = datetime.now()

    arrival = now + timedelta(minutes=float(eta_minutes))

    day_of_week = arrival.weekday()  # 0 = Monday
    minute_of_day = arrival.hour * 60 + arrival.minute  # 0..1439

    return [[day_of_week, minute_of_day]]


def predict_empty_probability(
    num_empty: int,
    num_total: int,
    eta_minutes: float,
) -> float:
    """
    Predict P(at least one spot is empty at arrival time).

    Parameters (unchanged from original):
      - num_empty: current number of empty spots (from camera/LLM)
      - num_total: total number of spots (6 in your demo)
      - eta_minutes: user's ETA in minutes

    Implementation:
      - Compute arrival time = now + eta_minutes
      - Convert to (day_of_week, minute_of_day)
      - Query the trained model for P(any empty at that time)
    """
    # If there is already an empty spot and ETA is ~0, you could shortcut,
    # but we let the model handle it for simplicity/consistency.
    X = _arrival_features(eta_minutes)
    proba_any_empty = _model.predict_proba(X)[0][1]  # class 1 = "any empty"

    # Clamp to [0,1] just in case of numeric quirks
    return float(max(0.0, min(1.0, proba_any_empty)))


def expected_wait_minutes(
    num_empty: int,
    num_total: int,
    target_confidence: float = 0.8,
    max_wait: int = 60,
) -> float:
    """
    Estimate how long the driver should expect to wait until we reach
    a desired confidence of finding a spot.

    Parameters (same as before):
      - num_empty: current number of empty spots
      - num_total: total spots (not heavily used here)
      - target_confidence: e.g. 0.8 for 80% chance of availability
      - max_wait: upper bound on wait time we search over (minutes)

    Strategy:
      - If there are already empty spots now, return 0.
      - Otherwise, search w = 0..max_wait and return the smallest w
        such that P(any empty at time now + w) >= target_confidence.
      - If no such w is found, return max_wait.
    """
    # Already at least one empty spot visible now -> no wait.
    if num_empty > 0:
        return 0.0

    for w in range(0, max_wait + 1):
        p = predict_empty_probability(num_empty, num_total, w)
        if p >= target_confidence:
            return float(w)

    # If we never hit the threshold, just return the cap.
    return float(max_wait)

