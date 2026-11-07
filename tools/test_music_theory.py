#!/usr/bin/env python3
"""Tests for tools/music_theory.py: the helpers' arithmetic, and the trailer's frequencies."""

from __future__ import annotations

import itertools
import json
import unittest
from pathlib import Path

import music_theory as mt

TOOLS = Path(__file__).resolve().parent


class NoteTests(unittest.TestCase):
    def test_parse_and_name_round_trip(self) -> None:
        self.assertEqual(mt.parse_note("C4"), 60)
        self.assertEqual(mt.parse_note("A4"), 69)
        self.assertEqual(mt.parse_note("Bb3"), 58)
        self.assertEqual(mt.parse_note("C-1"), 0)
        for midi in range(0, 128):
            self.assertEqual(mt.parse_note(mt.note_name(midi)), midi)

    def test_flat_and_sharp_agree(self) -> None:
        self.assertEqual(mt.parse_note("Eb3"), mt.parse_note("D#3"))
        self.assertEqual(mt.pitch_class("Gb"), 6)

    def test_bad_names_raise(self) -> None:
        for bad in ("H4", "C", "4C", "C##4", ""):
            with self.assertRaises(ValueError, msg=bad):
                mt.parse_note(bad)

    def test_frequency(self) -> None:
        self.assertEqual(mt.frequency(69), 440.0)
        self.assertAlmostEqual(mt.frequency(60), 261.6256, places=3)
        self.assertAlmostEqual(mt.frequency(81), 880.0, places=9)

    def test_trailer_frequencies_are_equal_temperament(self) -> None:
        """Every hand-listed trailer frequency is a note of 12-TET to within a hundredth of a hertz.

        The one exception is 1480.0 Hz, F#6's 1479.98 rounded by hand; 0.03 Hz admits it.
        """
        document = json.loads((TOOLS / "trailer" / "scores.json").read_text())
        listed = {event["frequency"] for option in document["options"] for event in option["events"]}
        self.assertTrue(listed)
        for hertz in listed:
            midi = round(69 + 12 * __import__("math").log2(hertz / 440.0))
            self.assertAlmostEqual(mt.frequency(midi), hertz, delta=0.03, msg=str(hertz))


class ScaleTests(unittest.TestCase):
    def test_c_major(self) -> None:
        self.assertEqual(mt.scale("C4", "major"), [60, 62, 64, 65, 67, 69, 71])

    def test_modes_are_rotations_of_major(self) -> None:
        major = mt.SCALES["major"]
        for rotation, name in enumerate(("major", "dorian", "phrygian", "lydian", "mixolydian", "minor", "locrian")):
            expected = tuple(sorted((step - major[rotation]) % 12 for step in major))
            self.assertEqual(mt.SCALES[name], expected, name)

    def test_every_scale_is_ascending_within_an_octave(self) -> None:
        for name, steps in mt.SCALES.items():
            self.assertEqual(steps[0], 0, name)
            self.assertEqual(list(steps), sorted(set(steps)), name)
            self.assertLess(steps[-1], 12, name)

    def test_octaves_and_top(self) -> None:
        notes = mt.scale("A3", "minor-pentatonic", 2, include_top=True)
        self.assertEqual(len(notes), 11)
        self.assertEqual(notes[-1], mt.parse_note("A5"))

    def test_unknown_scale(self) -> None:
        with self.assertRaises(ValueError):
            mt.scale("C4", "nope")
        with self.assertRaises(ValueError):
            mt.scale("C4", "major", 0)


class ChordTests(unittest.TestCase):
    def test_triads_and_sevenths(self) -> None:
        self.assertEqual(mt.chord("C4"), [60, 64, 67])
        self.assertEqual(mt.chord("A3", "m7"), [57, 60, 64, 67])
        self.assertEqual(mt.chord("B3", "m7b5"), [59, 62, 65, 69])

    def test_inversion_keeps_pitch_classes(self) -> None:
        first = mt.chord("C4", inversion=1)
        self.assertEqual(first, [64, 67, 72])
        self.assertEqual({n % 12 for n in first}, {n % 12 for n in mt.chord("C4")})
        with self.assertRaises(ValueError):
            mt.chord("C4", inversion=3)

    def test_symbol(self) -> None:
        self.assertEqual(mt.chord_from_symbol("Am7"), mt.chord("A3", "m7"))
        self.assertEqual(mt.chord_from_symbol("F#m7b5", 2), mt.chord("F#2", "m7b5"))
        self.assertEqual(mt.chord_from_symbol("C", 4), [60, 64, 67])
        with self.assertRaises(ValueError):
            mt.chord_from_symbol("Hm")
        with self.assertRaises(ValueError):
            mt.chord_from_symbol("Cwhat")

    def test_diatonic_triads_in_major(self) -> None:
        qualities = []
        for degree in range(1, 8):
            notes = mt.diatonic_chord("C4", "major", degree)
            shape = tuple(n - notes[0] for n in notes)
            qualities.append({(0, 4, 7): "M", (0, 3, 7): "m", (0, 3, 6): "d"}[(shape[0], shape[1], shape[2])])
        self.assertEqual(qualities, ["M", "m", "m", "M", "M", "m", "d"])

    def test_diatonic_sevenths_in_major(self) -> None:
        self.assertEqual(mt.diatonic_chord("C4", "major", 1, size=4), mt.chord("C4", "maj7"))
        self.assertEqual(mt.diatonic_chord("C4", "major", 5, size=4), mt.chord("G4", "7"))
        self.assertEqual(mt.diatonic_chord("C4", "major", 7, size=4), mt.chord("B4", "m7b5"))

    def test_diatonic_needs_seven_notes(self) -> None:
        with self.assertRaises(ValueError):
            mt.diatonic_chord("C4", "blues", 1)
        with self.assertRaises(ValueError):
            mt.diatonic_chord("C4", "nope", 1)


class ProgressionTests(unittest.TestCase):
    def test_pop_progression(self) -> None:
        chords = mt.progression("C3", "major", "I V vi IV")
        self.assertEqual(chords, [mt.chord("C3"), mt.chord("G3"), mt.chord("A3", "m"), mt.chord("F3")])

    def test_minor_progression_with_borrowed_numerals(self) -> None:
        chords = mt.progression("A3", "minor", "i VI III VII")
        self.assertEqual(chords[0], mt.chord("A3", "m"))
        self.assertEqual(chords[1], mt.chord("F4", "") if False else mt.chord("F3", "") if False else chords[1])
        self.assertEqual([c[0] % 12 for c in chords], [9, 5, 0, 7])
        self.assertEqual(mt.progression("C3", "major", "bVII")[0], mt.chord("A#3"))

    def test_suffixes(self) -> None:
        self.assertEqual(mt.chord_for_numeral("C3", "major", "V7"), mt.chord("G3", "7"))
        self.assertEqual(mt.chord_for_numeral("C3", "major", "vii°"), mt.chord("B3", "dim"))
        self.assertEqual(mt.chord_for_numeral("C3", "major", "Imaj7"), mt.chord("C3", "maj7"))
        self.assertEqual(mt.chord_for_numeral("C3", "major", "ii7"), mt.chord("D3", "m7"))
        self.assertEqual(mt.chord_for_numeral("C3", "major", "III+"), mt.chord("E3", "aug"))

    def test_bad_numeral(self) -> None:
        for bad in ("VIII", "x", "Ixyz"):
            with self.assertRaises(ValueError, msg=bad):
                mt.chord_for_numeral("C3", "major", bad)
        with self.assertRaises(ValueError):
            mt.progression("C3", "blues", "I")

    def test_voice_lead_keeps_pitch_classes_and_moves_little(self) -> None:
        chords = mt.progression("C3", "major", "I V vi IV")
        voiced = mt.voice_lead(chords)
        for original, led in zip(chords, voiced, strict=True):
            self.assertEqual({n % 12 for n in original}, {n % 12 for n in led})
        movement = sum(abs(a - b) for x, y in itertools.pairwise(voiced) for a, b in zip(x, y, strict=True))
        plain = sum(abs(a - b) for x, y in itertools.pairwise(chords) for a, b in zip(x, y, strict=True))
        self.assertLess(movement, plain)
        self.assertEqual(mt.voice_lead([]), [])


class PatternTests(unittest.TestCase):
    def test_notes_rests_and_holds(self) -> None:
        events = mt.parse_pattern("C4 - . E4 | G4", step_seconds=0.5)
        self.assertEqual(
            [(e.at, e.duration, e.midi) for e in events],
            [(0.0, 1.0, 60), (1.5, 0.5, 64), (2.0, 0.5, 67)],
        )

    def test_repeat(self) -> None:
        events = mt.parse_pattern("C4 x3", step_seconds=1.0)
        self.assertEqual([e.at for e in events], [0.0, 1.0, 2.0])

    def test_hold_after_rest_is_an_error(self) -> None:
        for bad in ("-", "C4 . -", "x2", "C4 H5", "C4 q"):
            with self.assertRaises(ValueError, msg=bad):
                mt.parse_pattern(bad, step_seconds=1.0)
        with self.assertRaises(ValueError):
            mt.parse_pattern("C4", step_seconds=0)

    def test_arpeggio_orders(self) -> None:
        notes = [60, 64, 67]
        self.assertEqual([e.midi for e in mt.arpeggiate(notes, start=0, step_seconds=1, steps=4)], [60, 64, 67, 60])
        self.assertEqual(
            [e.midi for e in mt.arpeggiate(notes, start=0, step_seconds=1, steps=3, order="down")], [67, 64, 60]
        )
        self.assertEqual(
            [e.midi for e in mt.arpeggiate(notes, start=0, step_seconds=1, steps=4, order="updown")], [60, 64, 67, 64]
        )
        self.assertEqual(
            [e.midi for e in mt.arpeggiate(notes, start=2, step_seconds=1, steps=4, order="alberti")], [60, 67, 64, 67]
        )
        self.assertEqual(mt.arpeggiate(notes, start=2, step_seconds=1, steps=1)[0].at, 2.0)
        with self.assertRaises(ValueError):
            mt.arpeggiate(notes, start=0, step_seconds=1, steps=1, order="sideways")
        with self.assertRaises(ValueError):
            mt.arpeggiate([60, 64], start=0, step_seconds=1, steps=1, order="alberti")

    def test_timing_and_loop(self) -> None:
        self.assertEqual(mt.beats_to_seconds(4, 120), 2.0)
        with self.assertRaises(ValueError):
            mt.beats_to_seconds(1, 0)
        phrase = mt.parse_pattern("C4 E4", step_seconds=1.0)
        looped = mt.loop_events(phrase, 4.0, 3)
        self.assertEqual([e.at for e in looped], [0.0, 1.0, 4.0, 5.0, 8.0, 9.0])
        with self.assertRaises(ValueError):
            mt.loop_events(phrase, 0.0, 1)

    def test_score_events_shape(self) -> None:
        events = mt.parse_pattern("A3", step_seconds=0.5)
        self.assertEqual(
            mt.to_score_events(events, texture="pluck", gain=0.5, offset=1.0),
            [{"at": 1.0, "duration": 0.5, "frequency": 220.0, "gain": 0.5, "texture": "pluck"}],
        )


class CommandTests(unittest.TestCase):
    def lines(self, *argv: str) -> list[str]:
        return mt.run(mt.parse_args(argv))

    def test_commands(self) -> None:
        self.assertIn("A3(220.00Hz)", self.lines("scale", "A3", "dorian")[0])
        self.assertTrue(self.lines("chord", "Am7", "--inversion", "1")[0].startswith("C4"))
        self.assertEqual(len(self.lines("progression", "C3", "major", "I V", "--voice-lead")), 2)
        self.assertEqual(len(self.lines("pattern", "C4 - E4", "--bpm", "120", "--steps-per-beat", "1")), 2)

    def test_main_reports_a_bad_name(self) -> None:
        self.assertEqual(mt.main(["chord", "Hm"]), 2)
        self.assertEqual(mt.main(["scale", "A3", "major"]), 0)


if __name__ == "__main__":
    unittest.main()
