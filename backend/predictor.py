# backend/predictor.py
#
# Simple rule-based "model" for parking availability.
# It behaves like something we trained on historical data,
# but is implemented as lookup tables for now.

from datetime import datetime
from typing import Literal

DayType = Literal["weekday", "weekend"]

# Probability that a spot is EMPTY by day type and hour (0-23).
# These numbers encode assumptions about class times and behavior
# around the engineering building.
PROB_EMPTY_BY_HOUR = {
    "weekday": {
        # Night / very early: mostly empty
        0: 0.96, 1: 0.97, 2: 0.98, 3: 0.98, 4: 0.97, 5: 0.95,
        # Early morning commute
        6: 0.6, 7: 0.5,
        # Morning class blocks (busy)
        8: 0.3, 9: 0.2, 10: 0.25, 11: 0.3,
        # Midday / lunch, still busy
        12: 0.35, 13: 0.3, 14: 0.3, 15: 0.35,
        # Afternoon / people leaving
        16: 0.45, 17: 0.55,
        # Evening / mostly gone
        18: 0.65, 19: 0.75, 20: 0.85, 21: 0.9, 22: 0.93, 23: 0.95,
    },
    "weekend": {
        # Night / early morning: very empty
        0: 0.97, 1: 0.98, 2: 0.99, 3: 0.99, 4: 0.98, 5: 0.97,
        # Late morning: some people come in
        6: 0.9, 7: 0.88, 8: 0.85, 9: 0.8, 10: 0.78, 11: 0.75,
        # Midday bump
        12: 0.7, 13: 0.7, 14: 0.68, 15: 0.7,
        # Afternoon tapering
        16: 0.75, 17: 0.8,
        # Evening / night: mostly empty
        18: 0.85, 19: 0.9, 20: 0.93, 21: 0.95, 22: 0.97, 23: 0.98,
    },
}

# Expected wait time (minutes) until some spot opens up in the area,
# by day type and hour. Busy daytime = longer wait, nights = short wait.
EXPECTED_WAIT_MINUTES_BY_HOUR = {
    "weekday": {
        0: 2, 1: 2, 2: 2, 3: 2, 4: 2, 5: 3,
        6: 8, 7: 10,
        8: 18, 9: 20, 10: 18, 11: 16,
        12: 15, 13: 17, 14: 18, 15: 16,
        16: 12, 17: 10,
        18: 8, 19: 6, 20: 4, 21: 3, 22: 2, 23: 2,
    },
    "weekend": {
        0: 2, 1: 2, 2: 2, 3: 2, 4: 2, 5: 2,
        6: 3, 7: 4, 8: 5, 9: 6, 10: 7, 11: 7,
        12: 8, 13: 8, 14: 8, 15: 7,
        16: 6, 17: 5,
        18: 4, 19: 3, 20: 3, 21: 2, 22: 2, 23: 2,
    },
}


def _get_day_type(dt: datetime) -> DayType:
    """Return 'weekday' or 'weekend' given a datetime."""
    # Monday = 0, Sunday = 6
    return "weekend" if dt.weekday() >= 5 else "weekday"


def predict_empty_probability(arrival_dt: datetime) -> float:
    """
    Predict the probability that a random spot in this area is EMPTY
    at the given arrival time.

    In a more advanced version, this could depend on:
      - specific spot or area
      - class schedules
      - learned parameters from historical data
    For now, it uses a time-of-day + weekday/weekend lookup.
    """
    day_type = _get_day_type(arrival_dt)
    hour = arrival_dt.hour

    day_table = PROB_EMPTY_BY_HOUR.get(day_type, {})
    prob = day_table.get(hour)

    if prob is None:
        # Fallback if somehow hour is missing
        return 0.5

    return prob


def expected_wait_minutes(arrival_dt: datetime) -> float:
    """
    Predict expected wait time (in minutes) until some spot opens up
    in this area around the given time of day.
    """
    day_type = _get_day_type(arrival_dt)
    hour = arrival_dt.hour

    day_table = EXPECTED_WAIT_MINUTES_BY_HOUR.get(day_type, {})
    wait = day_table.get(hour)

    if wait is None:
        # Fallback
        return 10.0

    return float(wait)

