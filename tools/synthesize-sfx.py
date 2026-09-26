#!/usr/bin/env python3
"""Build the Copper lark procedural sound-effects audition.

The recipes use only standard-library oscillators, deterministic noise, envelopes and simple
filters. They write files for listening; they never play audio or install it into the game.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import math
import random
import wave
import zipfile
from array import array
from collections.abc import Callable, Sequence
from pathlib import Path
from typing import Final

SAMPLE_RATE: Final = 48_000
PCM_MAX: Final = 32_767
TARGET_PEAK: Final = 0.70
DEFAULT_SEED: Final = 260_926
DEFAULT_OUTPUT: Final = Path("docs/evidence/copper-lark-sound-lab-2026-09-26")
ARCHIVE_NAME: Final = "copper-lark-sound-lab.zip"

Signal = list[float]
Recipe = Callable[[int], Signal]

PAIRS: Final = (
    ("Footsteps", "footsteps-grounded.wav", "footsteps-stylized.wav"),
    ("Stroller wheels", "stroller-wheels-grounded.wav", "stroller-wheels-stylized.wav"),
    ("Car horn", "car-horn-grounded.wav", "car-horn-stylized.wav"),
    ("Loudspeaker crackle", "loudspeaker-crackle-grounded.wav", "loudspeaker-crackle-stylized.wav"),
)

RECIPE_NOTES: Final = {
    "footsteps-grounded.wav": (
        "Two irregular sole strikes: falling low sine thumps, low-passed grit and short filtered "
        "scrapes under exponential envelopes."
    ),
    "footsteps-stylized.wav": (
        "Two pitched impacts: downward sine chirps, a soft second harmonic and brief synthetic "
        "noise ticks."
    ),
    "stroller-wheels-grounded.wav": (
        "Low-passed rolling noise with slow load variation, four uneven pavement joints and a "
        "restrained axle resonance."
    ),
    "stroller-wheels-stylized.wav": (
        "A wobbling low oscillator, repeating rounded wheel pulses and bright but band-limited "
        "joint pips."
    ),
    "car-horn-grounded.wav": (
        "A two-frequency horn dyad with quiet upper harmonics, breath noise and mechanical attack "
        "and release ramps."
    ),
    "car-horn-stylized.wav": (
        "An exaggerated two-note honk with a downward pitch scoop, vibrato and a rounded harmonic "
        "edge."
    ),
    "loudspeaker-crackle-grounded.wav": (
        "Band-limited hiss, low electrical hum and a seeded set of short irregular electrical "
        "pops with resonant tails."
    ),
    "loudspeaker-crackle-stylized.wav": (
        "Stepped noise, amplitude-gated buzz and a seeded train of tonal digital spits, kept below "
        "the piercing upper band."
    ),
    "comparison.wav": (
        "The eight normalized auditions concatenated as grounded then stylized within each pair, "
        "with 0.45 seconds inside pairs and 1.0 second between pairs."
    ),
}


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate the deterministic Copper lark A/B sound-effects audition.",
        epilog=(
            "example: uv run python tools/synthesize-sfx.py --output "
            "docs/evidence/copper-lark-sound-lab-2026-09-26 --seed 260926"
        ),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        metavar="DIR",
        help=f"directory to write (default: {DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=DEFAULT_SEED,
        metavar="INTEGER",
        help=f"master seed for every recipe (default: {DEFAULT_SEED})",
    )
    return parser.parse_args(argv)


def _frames(seconds: float) -> int:
    return round(seconds * SAMPLE_RATE)


def _rng(seed: int, label: str) -> random.Random:
    digest = hashlib.sha256(f"{seed}:{label}".encode()).digest()
    return random.Random(int.from_bytes(digest[:16], "big"))


def _lowpass(values: Sequence[float], cutoff_hz: float) -> Signal:
    alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff_hz / SAMPLE_RATE)
    state = 0.0
    result: Signal = []
    for value in values:
        state += alpha * (value - state)
        result.append(state)
    return result


def _noise(count: int, rng: random.Random) -> Signal:
    return [rng.uniform(-1.0, 1.0) for _ in range(count)]


def _smooth_gate(t: float, start: float, end: float, ramp: float) -> float:
    if t < start or t >= end:
        return 0.0
    attack = min(1.0, (t - start) / ramp)
    release = min(1.0, (end - t) / ramp)
    return math.sin(0.5 * math.pi * attack) ** 2 * math.sin(0.5 * math.pi * release) ** 2


def _finish(values: Signal, target_peak: float = TARGET_PEAK) -> Signal:
    mean = sum(values) / len(values)
    centered = [value - mean for value in values]
    fade_frames = _frames(0.012)
    for index in range(fade_frames):
        gain = math.sin(0.5 * math.pi * index / fade_frames) ** 2
        centered[index] *= gain
        centered[-1 - index] *= gain
    peak = max(abs(value) for value in centered)
    if peak == 0.0:
        raise ValueError("recipe produced silence")
    scale = target_peak / peak
    finished = [value * scale for value in centered]
    finished[0] = 0.0
    finished[-1] = 0.0
    return finished


def footsteps_grounded(seed: int) -> Signal:
    count = _frames(1.15)
    rng = _rng(seed, "footsteps-grounded")
    grit = _lowpass(_noise(count, rng), 2_600.0)
    scrape = _lowpass(_noise(count, rng), 1_100.0)
    values = [0.0] * count
    for start, weight in ((0.14, 1.0), (0.69, 0.84)):
        for index in range(round(start * SAMPLE_RATE), min(count, round((start + 0.24) * SAMPLE_RATE))):
            tau = index / SAMPLE_RATE - start
            thud_phase = 2.0 * math.pi * (82.0 * tau - 74.0 * tau * tau)
            thud = math.sin(thud_phase) * math.exp(-27.0 * tau)
            contact = grit[index] * math.exp(-46.0 * tau)
            drag = scrape[index] * _smooth_gate(tau, 0.025, 0.19, 0.025)
            values[index] += weight * (0.84 * thud + 0.27 * contact + 0.12 * drag)
    return _finish(values)


def footsteps_stylized(seed: int) -> Signal:
    count = _frames(1.15)
    rng = _rng(seed, "footsteps-stylized")
    ticks = _lowpass(_noise(count, rng), 3_400.0)
    values = [0.0] * count
    for start, pitch, weight in ((0.13, 138.0, 1.0), (0.67, 119.0, 0.9)):
        phase = 0.0
        for index in range(round(start * SAMPLE_RATE), min(count, round((start + 0.29) * SAMPLE_RATE))):
            tau = index / SAMPLE_RATE - start
            frequency = max(66.0, pitch - 250.0 * tau)
            phase += 2.0 * math.pi * frequency / SAMPLE_RATE
            body = (math.sin(phase) + 0.24 * math.sin(2.0 * phase)) * math.exp(-16.0 * tau)
            click = ticks[index] * math.exp(-68.0 * tau)
            values[index] += weight * (0.72 * body + 0.18 * click)
    return _finish(values)


def stroller_wheels_grounded(seed: int) -> Signal:
    count = _frames(2.2)
    rng = _rng(seed, "stroller-wheels-grounded")
    raw_noise = _noise(count, rng)
    rumble = _lowpass(raw_noise, 310.0)
    texture = _lowpass(raw_noise, 2_100.0)
    values = [0.0] * count
    for index in range(count):
        t = index / SAMPLE_RATE
        load = 0.76 + 0.16 * math.sin(2.0 * math.pi * 1.7 * t) + 0.08 * math.sin(2.0 * math.pi * 3.1 * t + 0.8)
        values[index] = load * (0.34 * rumble[index] + 0.10 * texture[index])
    for start, weight in ((0.34, 0.64), (0.83, 0.82), (1.39, 0.61), (1.92, 0.76)):
        for index in range(round(start * SAMPLE_RATE), min(count, round((start + 0.1) * SAMPLE_RATE))):
            tau = index / SAMPLE_RATE - start
            bump = math.sin(2.0 * math.pi * 104.0 * tau) * math.exp(-42.0 * tau)
            axle = math.sin(2.0 * math.pi * 610.0 * tau) * math.exp(-55.0 * tau)
            values[index] += weight * (0.48 * bump + 0.07 * axle)
    return _finish(values)


def stroller_wheels_stylized(seed: int) -> Signal:
    count = _frames(2.2)
    rng = _rng(seed, "stroller-wheels-stylized")
    pips = _lowpass(_noise(count, rng), 3_000.0)
    values = [0.0] * count
    phase = 0.0
    for index in range(count):
        t = index / SAMPLE_RATE
        wobble = 94.0 + 12.0 * math.sin(2.0 * math.pi * 2.7 * t)
        phase += 2.0 * math.pi * wobble / SAMPLE_RATE
        wheel = 0.18 * math.sin(phase) * (0.6 + 0.4 * math.sin(2.0 * math.pi * 3.2 * t) ** 2)
        rounded_pulse = max(0.0, math.sin(2.0 * math.pi * 3.2 * t)) ** 5
        values[index] = wheel + 0.16 * rounded_pulse * math.sin(2.0 * phase) + 0.035 * pips[index] * rounded_pulse
    for start in (0.31, 0.82, 1.36, 1.88):
        for index in range(round(start * SAMPLE_RATE), min(count, round((start + 0.07) * SAMPLE_RATE))):
            tau = index / SAMPLE_RATE - start
            values[index] += 0.23 * math.sin(2.0 * math.pi * (780.0 - 2_400.0 * tau) * tau) * math.exp(-60.0 * tau)
    return _finish(values)


def car_horn_grounded(seed: int) -> Signal:
    count = _frames(1.18)
    rng = _rng(seed, "car-horn-grounded")
    breath = _lowpass(_noise(count, rng), 1_500.0)
    values = [0.0] * count
    phase_a = 0.0
    phase_b = 0.0
    for index in range(count):
        t = index / SAMPLE_RATE
        envelope = _smooth_gate(t, 0.11, 1.01, 0.055)
        drift = 1.0 + 0.0025 * math.sin(2.0 * math.pi * 5.1 * t)
        phase_a += 2.0 * math.pi * 326.0 * drift / SAMPLE_RATE
        phase_b += 2.0 * math.pi * 389.0 * drift / SAMPLE_RATE
        dyad = math.sin(phase_a) + 0.86 * math.sin(phase_b)
        brass = 0.13 * math.sin(2.0 * phase_a) + 0.09 * math.sin(2.0 * phase_b)
        values[index] = envelope * (0.46 * dyad + brass + 0.035 * breath[index])
    return _finish(values)


def car_horn_stylized(seed: int) -> Signal:
    count = _frames(1.18)
    rng = _rng(seed, "car-horn-stylized")
    edge = _lowpass(_noise(count, rng), 2_100.0)
    values = [0.0] * count
    phase_a = 0.0
    phase_b = 0.0
    for index in range(count):
        t = index / SAMPLE_RATE
        envelope = _smooth_gate(t, 0.09, 1.02, 0.07)
        active_t = max(0.0, t - 0.09)
        scoop = 58.0 * math.exp(-8.0 * active_t)
        vibrato = 6.0 * math.sin(2.0 * math.pi * 6.2 * active_t)
        base = 356.0 + scoop + vibrato
        phase_a += 2.0 * math.pi * base / SAMPLE_RATE
        phase_b += 2.0 * math.pi * base * 1.24 / SAMPLE_RATE
        rounded = math.tanh(1.4 * (math.sin(phase_a) + 0.72 * math.sin(phase_b)))
        values[index] = envelope * (0.54 * rounded + 0.07 * math.sin(2.0 * phase_a) + 0.025 * edge[index])
    return _finish(values)


def loudspeaker_crackle_grounded(seed: int) -> Signal:
    count = _frames(1.85)
    rng = _rng(seed, "loudspeaker-crackle-grounded")
    raw = _noise(count, rng)
    hiss_low = _lowpass(raw, 3_400.0)
    hiss_body = _lowpass(raw, 420.0)
    values = [0.0] * count
    for index in range(count):
        t = index / SAMPLE_RATE
        gate = 0.22 + 0.16 * max(0.0, math.sin(2.0 * math.pi * 7.7 * t + 0.4))
        hum = 0.055 * math.sin(2.0 * math.pi * 60.0 * t) + 0.025 * math.sin(2.0 * math.pi * 120.0 * t)
        values[index] = gate * (0.17 * hiss_low[index] + 0.12 * hiss_body[index]) + hum
    pop_starts = sorted(rng.uniform(0.08, 1.69) for _ in range(21))
    for start in pop_starts:
        weight = rng.uniform(0.28, 0.85)
        resonance = rng.uniform(720.0, 1_650.0)
        for index in range(round(start * SAMPLE_RATE), min(count, round((start + 0.035) * SAMPLE_RATE))):
            tau = index / SAMPLE_RATE - start
            snap = (1.0 if tau < 0.0013 else 0.0) * rng.uniform(-1.0, 1.0)
            tail = math.sin(2.0 * math.pi * resonance * tau) * math.exp(-125.0 * tau)
            values[index] += weight * (0.35 * snap + 0.18 * tail)
    return _finish(values)


def loudspeaker_crackle_stylized(seed: int) -> Signal:
    count = _frames(1.85)
    rng = _rng(seed, "loudspeaker-crackle-stylized")
    held_noise = 0.0
    values = [0.0] * count
    phase = 0.0
    hold_frames = 48
    for index in range(count):
        t = index / SAMPLE_RATE
        if index % hold_frames == 0:
            held_noise = rng.uniform(-1.0, 1.0)
        phase += 2.0 * math.pi * (176.0 + 19.0 * math.sin(2.0 * math.pi * 2.3 * t)) / SAMPLE_RATE
        hard_gate = 1.0 if math.sin(2.0 * math.pi * 9.5 * t) > 0.18 else 0.14
        values[index] = hard_gate * (0.12 * held_noise + 0.09 * math.sin(phase) + 0.035 * math.sin(3.0 * phase))
    spit_starts = sorted(rng.uniform(0.06, 1.73) for _ in range(27))
    for start in spit_starts:
        weight = rng.uniform(0.22, 0.62)
        pitch = rng.choice((840.0, 1_120.0, 1_440.0, 1_760.0))
        for index in range(round(start * SAMPLE_RATE), min(count, round((start + 0.026) * SAMPLE_RATE))):
            tau = index / SAMPLE_RATE - start
            values[index] += weight * math.sin(2.0 * math.pi * pitch * tau) * math.exp(-145.0 * tau)
    return _finish(values)


RECIPES: Final[dict[str, Recipe]] = {
    "footsteps-grounded.wav": footsteps_grounded,
    "footsteps-stylized.wav": footsteps_stylized,
    "stroller-wheels-grounded.wav": stroller_wheels_grounded,
    "stroller-wheels-stylized.wav": stroller_wheels_stylized,
    "car-horn-grounded.wav": car_horn_grounded,
    "car-horn-stylized.wav": car_horn_stylized,
    "loudspeaker-crackle-grounded.wav": loudspeaker_crackle_grounded,
    "loudspeaker-crackle-stylized.wav": loudspeaker_crackle_stylized,
}


def _comparison(signals: dict[str, Signal]) -> Signal:
    result: Signal = []
    pair_gap = [0.0] * _frames(0.45)
    subject_gap = [0.0] * _frames(1.0)
    for index, (_, grounded, stylized) in enumerate(PAIRS):
        result.extend(signals[grounded])
        result.extend(pair_gap)
        result.extend(signals[stylized])
        if index != len(PAIRS) - 1:
            result.extend(subject_gap)
    return _finish(result)


def _pcm_bytes(values: Sequence[float]) -> bytes:
    samples = array("h", (round(max(-1.0, min(1.0, value)) * PCM_MAX) for value in values))
    if samples.itemsize != 2:
        raise RuntimeError("platform short is not 16 bits")
    if __import__("sys").byteorder != "little":
        samples.byteswap()
    return samples.tobytes()


def _wav_bytes(values: Sequence[float]) -> bytes:
    destination = io.BytesIO()
    with wave.open(destination, "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(_pcm_bytes(values))
    return destination.getvalue()


def _audio_metadata(filename: str, values: Sequence[float], data: bytes) -> dict[str, object]:
    peak = max(abs(value) for value in values)
    rms = math.sqrt(sum(value * value for value in values) / len(values))
    return {
        "duration_seconds": round(len(values) / SAMPLE_RATE, 6),
        "frames": len(values),
        "peak_dbfs": round(20.0 * math.log10(peak), 3),
        "peak_linear": round(peak, 6),
        "recipe": RECIPE_NOTES[filename],
        "rms_dbfs": round(20.0 * math.log10(rms), 3),
        "sha256": hashlib.sha256(data).hexdigest(),
    }


def _comparison_order() -> list[str]:
    return [filename for _, grounded, stylized in PAIRS for filename in (grounded, stylized)]


def _readme(seed: int) -> str:
    order = "\n".join(f"{index}. `{name}`" for index, name in enumerate(_comparison_order(), 1))
    return f"""# Copper lark sound lab

This folder is a listening audition. It is not installed in the game and makes no claim that the
sounds are realistic or approved. Every sound comes from the tracked Python recipe: oscillators,
seeded noise, envelopes and simple filters, with no recordings, downloads, sample libraries or
pretrained audio.

Open `index.html` for labeled A/B controls. The grounded treatment is A and the stylized treatment
is B. `comparison.wav` plays this order, with 0.45 seconds between A and B and 1.0 second between
subjects:

{order}

## Rebuild

From the repository root, with the locked Python 3.14 environment:

```sh
uv run python tools/synthesize-sfx.py --output docs/evidence/copper-lark-sound-lab-2026-09-26 --seed {seed}
```

The generator defaults to that output directory and seed. It writes files only; it does not play
audio. The ZIP also carries a copy of the exact generator as `recipe/synthesize-sfx.py`.

## Format and level

All WAVs are 48 kHz, mono, signed PCM16. Each individual audition and the comparison file is
DC-centered, faded over 12 ms at both boundaries and normalized to a 0.70 linear peak (about
-3.1 dBFS). Equal peak targets make A/B playback comparable while leaving mix headroom. They do
not make perceived loudness identical, so listen at a comfortable device volume.

`manifest.json` records the seed, recipe chain, duration, measured peak and RMS, file hashes and
the generator hash. The test suite rebuilds two temporary copies and checks them byte for byte in
the pinned environment. Floating-point math implementations can differ across operating systems,
so this is not a blanket promise of cross-platform bit identity.
"""


def _review_page() -> str:
    cards = []
    for title, grounded, stylized in PAIRS:
        cards.append(
            f"""<section class="pair">
      <h2>{title}</h2>
      <div class="takes">
        <article><span>A</span><h3>Grounded</h3><audio controls preload="metadata" src="{grounded}"></audio><a download href="{grounded}">Download WAV</a></article>
        <article><span>B</span><h3>Stylized</h3><audio controls preload="metadata" src="{stylized}"></audio><a download href="{stylized}">Download WAV</a></article>
      </div>
    </section>"""
        )
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Copper lark sound lab</title>
  <style>
    :root {{ color-scheme: dark; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; background: #171816; color: #f2ecdc; }}
    body {{ max-width: 920px; margin: 0 auto; padding: 40px 20px 72px; }}
    header {{ border: 1px solid #6f765e; padding: 24px; background: #20231f; box-shadow: 7px 7px 0 #0b0c0a; }}
    h1 {{ margin: 0 0 10px; font-size: clamp(2rem, 7vw, 4.5rem); line-height: .92; letter-spacing: -.07em; }}
    p {{ line-height: 1.55; max-width: 72ch; }}
    .actions {{ display: flex; flex-wrap: wrap; gap: 10px; margin-top: 20px; }}
    a {{ color: #ffd26d; }}
    .button {{ padding: 10px 14px; border: 1px solid #ffd26d; text-decoration: none; background: #323327; }}
    .pair {{ margin-top: 32px; }}
    .pair > h2 {{ font-size: 1.35rem; border-bottom: 1px solid #6f765e; padding-bottom: 8px; }}
    .takes {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 14px; }}
    article {{ position: relative; padding: 18px; background: #292c27; border: 1px solid #545a4b; }}
    article span {{ float: right; display: grid; place-items: center; width: 34px; height: 34px; border-radius: 50%; background: #ca493d; color: white; font-weight: 800; }}
    h3 {{ margin: 0 0 18px; }}
    audio {{ display: block; width: 100%; margin-bottom: 12px; }}
    footer {{ margin-top: 38px; color: #c0bdaf; font-size: .9rem; }}
  </style>
</head>
<body>
  <header>
    <h1>Copper lark<br>sound lab</h1>
    <p>Four original procedural effects, each in a tactile grounded treatment and a clearly synthetic treatment. These are listening auditions and are not installed in the game.</p>
    <div class="actions"><a class="button" href="comparison.wav">Play the ordered comparison</a><a class="button" download href="{ARCHIVE_NAME}">Download the complete ZIP</a><a class="button" href="README.md">Read the recipe notes</a></div>
  </header>
  {''.join(cards)}
  <footer>48 kHz mono PCM16 · common 0.70 peak target · deterministic seed and hashes in <a href="manifest.json">manifest.json</a></footer>
</body>
</html>
"""


def _write_archive(output: Path, filenames: Sequence[str], generator_data: bytes) -> None:
    archive_path = output / ARCHIVE_NAME
    with zipfile.ZipFile(archive_path, "w") as archive:
        for filename in filenames:
            info = zipfile.ZipInfo(filename, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o644 << 16
            archive.writestr(info, (output / filename).read_bytes())
        recipe_info = zipfile.ZipInfo("recipe/synthesize-sfx.py", date_time=(1980, 1, 1, 0, 0, 0))
        recipe_info.compress_type = zipfile.ZIP_DEFLATED
        recipe_info.create_system = 3
        recipe_info.external_attr = 0o644 << 16
        archive.writestr(recipe_info, generator_data)


def generate(output: Path, seed: int) -> None:
    output.mkdir(parents=True, exist_ok=True)
    signals = {filename: recipe(seed) for filename, recipe in RECIPES.items()}
    signals["comparison.wav"] = _comparison(signals)

    audio_metadata: dict[str, dict[str, object]] = {}
    for filename, values in signals.items():
        data = _wav_bytes(values)
        (output / filename).write_bytes(data)
        audio_metadata[filename] = _audio_metadata(filename, values, data)

    generator_data = Path(__file__).read_bytes()
    archive_files = ["index.html", "README.md", "manifest.json", *signals]
    manifest = {
        "archive_contents": [*archive_files, "recipe/synthesize-sfx.py"],
        "comparison_order": _comparison_order(),
        "files": audio_metadata,
        "generator": "tools/synthesize-sfx.py",
        "generator_sha256": hashlib.sha256(generator_data).hexdigest(),
        "method": "Handwritten procedural synthesis using standard-library oscillators, seeded noise, envelopes and filters.",
        "mix_target_peak": TARGET_PEAK,
        "reproducibility": {
            "guarantee": (
                "Two rebuilds are checked byte-for-byte with the tracked generator and locked Python 3.14 environment."
            ),
            "limit": (
                "No blanket cross-platform bit-identical promise is made because platform math implementations may differ."
            ),
        },
        "sample_format": {"bits": 16, "channels": 1, "encoding": "signed PCM", "sample_rate_hz": SAMPLE_RATE},
        "seed": seed,
        "status": "standalone audition; not installed in the game",
    }
    (output / "README.md").write_text(_readme(seed), encoding="utf-8")
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (output / "index.html").write_text(_review_page(), encoding="utf-8")
    _write_archive(output, archive_files, generator_data)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    generate(args.output, args.seed)
    print(f"Generated {len(RECIPES) + 1} WAV files and {ARCHIVE_NAME} in {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
