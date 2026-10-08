#!/usr/bin/env python3
"""Synthesize one resolved trailer-score option as deterministic stereo PCM16."""

from __future__ import annotations

import argparse
import json
import math
import sys
import wave
from array import array
from collections.abc import Sequence
from pathlib import Path
from typing import Final, cast

SAMPLE_RATE: Final = 48_000
PCM_MAX: Final = 32_767
FADE_IN_SECONDS: Final = 0.12
FADE_OUT_SECONDS: Final = 0.25


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Synthesize one option from trailer.sh's resolved score JSON.",
    )
    parser.add_argument("--resolved", type=Path, required=True, help="resolved score JSON")
    parser.add_argument("--option", required=True, help="score option id")
    parser.add_argument("--output", type=Path, required=True, help="destination PCM16 WAV")
    return parser.parse_args(argv)


def number(value: object, label: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{label} must be a number")
    return float(value)


def oscillator(texture: str, phase: float, local_time: float, absolute_time: float, duration: float) -> float:
    envelope = math.sin(math.pi * local_time / duration) ** 2
    if texture == "pluck":
        return (math.sin(phase) + 0.22 * math.sin(2.0 * phase)) * envelope
    if texture == "glass":
        return (math.sin(phase) + 0.32 * math.sin(2.01 * phase) + 0.12 * math.sin(4.07 * phase)) * envelope
    if texture == "pulse":
        return (math.sin(phase) + 0.18 * math.sin(3.0 * phase)) * envelope
    if texture == "drone":
        movement = 0.82 + 0.18 * math.sin(2.0 * math.pi * 0.37 * absolute_time)
        return (math.sin(phase) + 0.16 * math.sin(0.5 * phase)) * movement * envelope
    if texture == "tick":
        return (
            (math.sin(phase) + 0.25 * math.sin(3.0 * phase))
            * math.exp(-8.0 * local_time / duration)
            * math.sin(math.pi * local_time / duration)
        )
    raise ValueError(f"unknown texture: {texture}")


def load_option(path: Path, option_id: str) -> tuple[float, list[dict[str, object]]]:
    document = cast(object, json.loads(path.read_text()))
    if not isinstance(document, dict):
        raise ValueError("resolved score must be an object")
    resolved = cast(dict[str, object], document)
    total_seconds = number(resolved.get("total_seconds"), "total_seconds")
    options = resolved.get("options")
    if not isinstance(options, list):
        raise ValueError("resolved score options must be an array")
    matches: list[dict[str, object]] = []
    for raw_option in options:
        if isinstance(raw_option, dict) and raw_option.get("id") == option_id:
            matches.append(cast(dict[str, object], raw_option))
    if len(matches) != 1:
        raise ValueError(f"expected one score option named {option_id!r}")
    raw_events = matches[0].get("events")
    if not isinstance(raw_events, list) or not raw_events:
        raise ValueError(f"score option {option_id!r} has no events")
    events: list[dict[str, object]] = []
    for raw_event in raw_events:
        if not isinstance(raw_event, dict):
            raise ValueError(f"score option {option_id!r} has a non-object event")
        events.append(cast(dict[str, object], raw_event))
    return total_seconds, events


def synthesize(total_seconds: float, events: list[dict[str, object]]) -> array[float]:
    sample_count = round(total_seconds * SAMPLE_RATE)
    signal = array("d", [0.0]) * sample_count
    for event_index, event in enumerate(events):
        prefix = f"event {event_index}"
        at = number(event.get("at"), f"{prefix}.at")
        duration = number(event.get("duration"), f"{prefix}.duration")
        frequency = number(event.get("frequency"), f"{prefix}.frequency")
        gain = number(event.get("gain"), f"{prefix}.gain")
        texture = event.get("texture")
        if not isinstance(texture, str):
            raise ValueError(f"{prefix}.texture must be a string")
        start = round(at * SAMPLE_RATE)
        event_samples = round(duration * SAMPLE_RATE)
        if start < 0 or event_samples <= 0 or start + event_samples > sample_count:
            raise ValueError(f"{prefix} lies outside the resolved score duration")
        for offset in range(event_samples):
            local_time = offset / SAMPLE_RATE
            absolute_time = (start + offset) / SAMPLE_RATE
            phase = 2.0 * math.pi * frequency * local_time
            signal[start + offset] += gain * oscillator(texture, phase, local_time, absolute_time, duration)
    return signal


def write_pcm(path: Path, signal: array[float], total_seconds: float) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    chunk = array("h")
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        for index, raw_value in enumerate(signal):
            absolute_time = index / SAMPLE_RATE
            fade = min(1.0, absolute_time / FADE_IN_SECONDS)
            fade = min(fade, max(0.0, (total_seconds - absolute_time) / FADE_OUT_SECONDS))
            value = max(-1.0, min(1.0, raw_value * fade))
            sample = round(value * PCM_MAX)
            chunk.extend((sample, sample))
            if len(chunk) >= 16_384:
                if sys.byteorder != "little":
                    chunk.byteswap()
                output.writeframes(chunk.tobytes())
                chunk = array("h")
        if chunk:
            if sys.byteorder != "little":
                chunk.byteswap()
            output.writeframes(chunk.tobytes())


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        total_seconds, events = load_option(args.resolved, args.option)
        write_pcm(args.output, synthesize(total_seconds, events), total_seconds)
    except (OSError, ValueError) as error:
        print(f"synthesize_score.py: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
