#!/usr/bin/env python3
"""Tests for the sound recipes' building blocks: the filters, the noise colours and the pictures."""

from __future__ import annotations

import importlib.util
import math
import random
import struct
import unittest
import zlib
from pathlib import Path

SPEC = importlib.util.spec_from_file_location("synth", Path(__file__).with_name("synthesize-sfx.py"))
assert SPEC and SPEC.loader
synth = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(synth)

RATE = synth.SAMPLE_RATE


def sine(hz: float, seconds: float, amplitude: float = 0.5) -> list[float]:
    return [amplitude * math.sin(2.0 * math.pi * hz * i / RATE) for i in range(round(seconds * RATE))]


def rms(values: list[float]) -> float:
    return math.sqrt(sum(v * v for v in values) / len(values))


def band_db(values: list[float], low_hz: float, high_hz: float) -> float:
    """Mean power in dB of the Hann-windowed spectra between two frequencies."""
    frames = synth._spectrogram(values)
    low, high = round(synth._bin_of(low_hz)), round(synth._bin_of(high_hz))
    power = [sum(m * m for m in frame[low : high + 1]) / (high - low + 1) for frame in frames]
    return 10.0 * math.log10(sum(power) / len(power))


class FftTests(unittest.TestCase):
    def test_fft_matches_a_direct_transform(self) -> None:
        data = [math.sin(0.7 * i) + 0.3 * math.cos(2.1 * i) for i in range(16)]
        fast = synth._fft([complex(v) for v in data])
        for k in range(16):
            direct = sum(
                data[n] * complex(math.cos(2 * math.pi * k * n / 16), -math.sin(2 * math.pi * k * n / 16))
                for n in range(16)
            )
            self.assertAlmostEqual(abs(fast[k] - direct), 0.0, places=9)


class BiquadTests(unittest.TestCase):
    def test_lowpass_passes_low_and_cuts_high(self) -> None:
        low = synth._biquad(sine(200.0, 0.3), "lowpass", 1_000.0)
        high = synth._biquad(sine(8_000.0, 0.3), "lowpass", 1_000.0)
        self.assertGreater(rms(low[RATE // 10 :]), 0.9 * rms(sine(200.0, 0.2)))
        self.assertLess(rms(high[RATE // 10 :]), 0.02)

    def test_highpass_passes_high_and_cuts_low(self) -> None:
        low = synth._biquad(sine(100.0, 0.3), "highpass", 2_000.0)
        high = synth._biquad(sine(8_000.0, 0.3), "highpass", 2_000.0)
        self.assertLess(rms(low[RATE // 10 :]), 0.01)
        self.assertGreater(rms(high[RATE // 10 :]), 0.9 * rms(sine(8_000.0, 0.2)))

    def test_bandpass_has_unity_gain_at_its_centre_and_q_narrows_it(self) -> None:
        centre = rms(synth._biquad(sine(1_000.0, 0.3), "bandpass", 1_000.0, 4.0)[RATE // 10 :])
        self.assertAlmostEqual(centre / rms(sine(1_000.0, 0.2)), 1.0, delta=0.03)
        off_narrow = rms(synth._biquad(sine(1_500.0, 0.3), "bandpass", 1_000.0, 8.0)[RATE // 10 :])
        off_wide = rms(synth._biquad(sine(1_500.0, 0.3), "bandpass", 1_000.0, 0.7)[RATE // 10 :])
        self.assertLess(off_narrow, off_wide)

    def test_a_sweep_moves_the_cutoff(self) -> None:
        noise = synth._noise(RATE, random.Random(1))
        swept = synth._biquad(noise, "lowpass", synth._sweep(300.0, 6_000.0, RATE))
        first, last = swept[: RATE // 4], swept[-RATE // 4 :]
        self.assertGreater(rms(last), 2.0 * rms(first))

    def test_unknown_kind_is_refused(self) -> None:
        with self.assertRaises(ValueError):
            synth._biquad([0.0], "notch", 1_000.0)


class NoiseColourTests(unittest.TestCase):
    def octave_drop(self, values: list[float]) -> float:
        """dB lost per octave between 200-400 Hz and 3200-6400 Hz (four octaves apart)."""
        return (band_db(values, 200.0, 400.0) - band_db(values, 3_200.0, 6_400.0)) / 4.0

    def test_slopes_are_white_flat_pink_three_and_brown_six_db_per_octave(self) -> None:
        count = RATE * 2
        white = synth._noise(count, random.Random(3))
        pink = synth._pink_noise(count, random.Random(3))
        brown = synth._brown_noise(count, random.Random(3))
        self.assertAlmostEqual(self.octave_drop(white), 0.0, delta=0.6)
        # a band of power per Hz: a band of noise a factor 16 wider holds 12 dB more, but
        # band_db is a per-bin mean, so the drop per octave is the slope itself
        self.assertAlmostEqual(self.octave_drop(pink), 3.0, delta=0.8)
        self.assertAlmostEqual(self.octave_drop(brown), 6.0, delta=1.2)

    def test_noise_is_deterministic_and_matches_white_rms(self) -> None:
        a = synth._pink_noise(5_000, random.Random(9))
        b = synth._pink_noise(5_000, random.Random(9))
        self.assertEqual(a, b)
        self.assertAlmostEqual(rms(a), 0.577, places=3)
        self.assertAlmostEqual(rms(synth._brown_noise(5_000, random.Random(9))), 0.577, places=3)


class PictureTests(unittest.TestCase):
    def test_analysis_finds_pitch_peak_and_clipping(self) -> None:
        values = sine(440.0, 0.5, 1.0)
        pcm = synth._pcm_bytes(values)
        report = synth._analysis(values, pcm, synth._spectrogram(values))
        self.assertAlmostEqual(report["pitch_median_hz"], 440.0, delta=3.0)  # type: ignore[arg-type]
        self.assertAlmostEqual(report["centroid_hz"], 440.0, delta=40.0)  # type: ignore[arg-type]
        self.assertGreater(report["clipped_samples"], 0)  # type: ignore[operator]
        self.assertAlmostEqual(report["peak_dbfs"], 0.0, places=2)  # type: ignore[arg-type]
        self.assertAlmostEqual(report["rms_dbfs"], -3.01, delta=0.05)  # type: ignore[arg-type]

    def test_noise_has_no_pitch_and_no_clipping(self) -> None:
        values = [0.3 * v for v in synth._noise(RATE // 2, random.Random(5))]
        report = synth._analysis(values, synth._pcm_bytes(values), synth._spectrogram(values))
        self.assertEqual(report["clipped_samples"], 0)
        self.assertLess(report["pitch_voiced_fraction"], 0.2)  # type: ignore[operator]

    def test_picture_is_a_valid_png_of_the_documented_size(self) -> None:
        values = sine(1_000.0, 0.3)
        png = synth._picture(values, synth._spectrogram(values))
        self.assertEqual(png[:8], b"\x89PNG\r\n\x1a\n")
        width, height, depth, colour = struct.unpack(">IIBB", png[16:26])
        self.assertEqual((width, depth, colour), (synth.PICTURE_WIDTH, 8, 2))
        self.assertEqual(height, synth.WAVE_HEIGHT + synth.SPECTRUM_HEIGHT + 4)
        # the IDAT chunk inflates to one filter byte plus the pixels, per row
        length = struct.unpack(">I", png[33:37])[0]
        raw = zlib.decompress(png[41 : 41 + length])
        self.assertEqual(len(raw), height * (1 + 3 * width))
        self.assertEqual(png, synth._picture(values, synth._spectrogram(values)), "pictures are deterministic")


if __name__ == "__main__":
    unittest.main()
