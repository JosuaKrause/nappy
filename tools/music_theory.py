#!/usr/bin/env python3
"""Scales, chords, progressions and pattern strings for authoring a game score.

Standard library only, written from the published definitions that docs/MUSIC.md cites (twelve-tone
equal temperament, the diatonic modes, tertian chords, Roman-numeral analysis). Nothing here plays
or writes audio: it turns a name such as "A minor" or "i VI III VII" into MIDI note numbers, then
into timed events shaped like the ones tools/trailer/synthesize_score.py reads (`at`, `duration`,
`frequency`, `gain`, `texture`). The game has no music; this is authoring help.

A MIDI note number counts semitones, middle C (C4) being 60 and A4 being 69.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Final

A4_MIDI: Final = 69
A4_HZ: Final = 440.0

# Spelled with sharps; flats are accepted on input and normalised by pitch class.
PITCH_CLASS_NAMES: Final = ("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
_LETTER_PITCH_CLASS: Final = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
_NOTE_RE: Final = re.compile(r"^([A-Ga-g])([#b]?)(-?\d+)$")
_PITCH_RE: Final = re.compile(r"^([A-Ga-g])([#b]?)$")

# Semitone steps above the root, one octave.
SCALES: Final[dict[str, tuple[int, ...]]] = {
    "major": (0, 2, 4, 5, 7, 9, 11),
    "minor": (0, 2, 3, 5, 7, 8, 10),
    "dorian": (0, 2, 3, 5, 7, 9, 10),
    "phrygian": (0, 1, 3, 5, 7, 8, 10),
    "lydian": (0, 2, 4, 6, 7, 9, 11),
    "mixolydian": (0, 2, 4, 5, 7, 9, 10),
    "locrian": (0, 1, 3, 5, 6, 8, 10),
    "harmonic-minor": (0, 2, 3, 5, 7, 8, 11),
    "melodic-minor": (0, 2, 3, 5, 7, 9, 11),
    "major-pentatonic": (0, 2, 4, 7, 9),
    "minor-pentatonic": (0, 3, 5, 7, 10),
    "blues": (0, 3, 5, 6, 7, 10),
    "whole-tone": (0, 2, 4, 6, 8, 10),
}

# Chord quality suffix to semitone steps above the root, in root position.
CHORD_QUALITIES: Final[dict[str, tuple[int, ...]]] = {
    "": (0, 4, 7),
    "m": (0, 3, 7),
    "dim": (0, 3, 6),
    "aug": (0, 4, 8),
    "sus2": (0, 2, 7),
    "sus4": (0, 5, 7),
    "5": (0, 7),
    "6": (0, 4, 7, 9),
    "m6": (0, 3, 7, 9),
    "7": (0, 4, 7, 10),
    "maj7": (0, 4, 7, 11),
    "m7": (0, 3, 7, 10),
    "m7b5": (0, 3, 6, 10),
    "dim7": (0, 3, 6, 9),
    "mMaj7": (0, 3, 7, 11),
    "add9": (0, 4, 7, 14),
    "madd9": (0, 3, 7, 14),
    "9": (0, 4, 7, 10, 14),
    "maj9": (0, 4, 7, 11, 14),
    "m9": (0, 3, 7, 10, 14),
}

_ROMAN_VALUES: Final = {"I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7}
_ROMAN_RE: Final = re.compile(r"^([b#]?)(VII|VI|IV|V|III|II|I|vii|vi|iv|v|iii|ii|i)(°|o|dim|\+|aug)?(maj7|7)?$")
_CHORD_RE: Final = re.compile(r"^([A-G][#b]?)(.*)$")


@dataclass(frozen=True)
class NoteEvent:
    """One sounding note: `at` seconds from the start, for `duration` seconds."""

    at: float
    duration: float
    midi: int
    gain: float = 1.0


def pitch_class(name: str) -> int:
    """Pitch class 0-11 of a note name without an octave: "C" is 0, "Eb" and "D#" are 3."""
    match = _PITCH_RE.match(name)
    if match is None:
        raise ValueError(f"not a pitch name: {name!r}")
    letter, accidental = match.groups()
    shift = {"": 0, "#": 1, "b": -1}[accidental]
    return (_LETTER_PITCH_CLASS[letter.upper()] + shift) % 12


def parse_note(name: str) -> int:
    """MIDI number of a note with an octave: "C4" is 60, "A4" is 69, "Bb3" is 58."""
    match = _NOTE_RE.match(name)
    if match is None:
        raise ValueError(f"not a note name with an octave: {name!r}")
    letter, accidental, octave = match.groups()
    shift = {"": 0, "#": 1, "b": -1}[accidental]
    return 12 * (int(octave) + 1) + _LETTER_PITCH_CLASS[letter.upper()] + shift


def note_name(midi: int) -> str:
    """The sharp-spelled name of a MIDI number: 60 is "C4"."""
    return f"{PITCH_CLASS_NAMES[midi % 12]}{midi // 12 - 1}"


def frequency(midi: int) -> float:
    """Frequency in hertz in equal temperament with A4 at 440 Hz."""
    return float(A4_HZ * 2.0 ** ((midi - A4_MIDI) / 12.0))


def scale(root: str, name: str, octaves: int = 1, *, include_top: bool = False) -> list[int]:
    """The notes of a scale from `root` (a note with octave, "A3"), ascending.

    `octaves` repeats the pattern; `include_top` adds the root an octave above the last note.
    """
    if name not in SCALES:
        raise ValueError(f"unknown scale {name!r}; known: {', '.join(SCALES)}")
    if octaves < 1:
        raise ValueError("octaves must be at least 1")
    base = parse_note(root)
    notes = [base + 12 * octave + step for octave in range(octaves) for step in SCALES[name]]
    if include_top:
        notes.append(base + 12 * octaves)
    return notes


def chord(root: str, quality: str = "", *, inversion: int = 0) -> list[int]:
    """The notes of a chord on `root` ("C3"), in the given inversion (0 is root position).

    An inversion moves the lowest note up an octave, so the chord keeps its pitch classes and its
    top note rises; it is how a progression keeps its voices close instead of leaping.
    """
    if quality not in CHORD_QUALITIES:
        raise ValueError(f"unknown chord quality {quality!r}; known: {', '.join(repr(q) for q in CHORD_QUALITIES)}")
    base = parse_note(root)
    notes = [base + step for step in CHORD_QUALITIES[quality]]
    if not 0 <= inversion < len(notes):
        raise ValueError(f"inversion {inversion} out of range for a {len(notes)}-note chord")
    for _ in range(inversion):
        notes.append(notes.pop(0) + 12)
    return notes


def chord_from_symbol(symbol: str, octave: int = 3, *, inversion: int = 0) -> list[int]:
    """A chord from its lead-sheet symbol: "C", "Am7", "F#m7b5", "Bbmaj7"; the root sits in `octave`."""
    match = _CHORD_RE.match(symbol)
    if match is None:
        raise ValueError(f"not a chord symbol: {symbol!r}")
    root, quality = match.groups()
    return chord(f"{root}{octave}", quality, inversion=inversion)


def diatonic_chord(root: str, scale_name: str, degree: int, *, size: int = 3) -> list[int]:
    """The chord built on scale degree `degree` (1-based) by stacking thirds inside the scale.

    `size` is the note count: 3 for a triad, 4 for a seventh chord, 5 for a ninth. The tonic's
    octave is `root`'s; stacking past the scale's top continues into the next octave.
    """
    steps = SCALES[scale_name] if scale_name in SCALES else _unknown_scale(scale_name)
    if len(steps) != 7:
        raise ValueError("diatonic chords need a seven-note scale")
    if degree < 1:
        raise ValueError("degree is 1-based")
    base = parse_note(root)

    def at_index(index: int) -> int:
        return base + 12 * (index // 7) + steps[index % 7]

    return [at_index(degree - 1 + 2 * k) for k in range(size)]


def _unknown_scale(name: str) -> tuple[int, ...]:
    raise ValueError(f"unknown scale {name!r}; known: {', '.join(SCALES)}")


def progression(key_root: str, mode: str, numerals: str) -> list[list[int]]:
    """Chords for a space-separated Roman-numeral progression in a key, as MIDI note lists.

    `key_root` is the tonic as a note with octave ("C3"); `mode` is a seven-note scale name.
    `chord_for_numeral` states how a numeral's case and suffix choose the quality.
    """
    return [chord_for_numeral(key_root, mode, token) for token in numerals.split()]


def chord_for_numeral(key_root: str, mode: str, token: str) -> list[int]:
    """One Roman numeral as a chord: upper case is major, lower case minor.

    The root is the scale degree of the numeral in `mode`, lowered or raised by a leading "b" or
    "#" (so "bVII" in major is the major chord on the flat seventh, the mixolydian borrowing).
    The case then sets the third, a suffix "°"/"o"/"dim" makes it diminished and "+"/"aug"
    augmented, and "7" adds the minor seventh while "maj7" adds the major seventh. This is
    the textbook reading, not the diatonic stacking of `diatonic_chord`: "V" is major in a minor key.
    """
    match = _ROMAN_RE.match(token)
    if match is None:
        raise ValueError(f"not a Roman numeral chord: {token!r}")
    accidental, numeral, flavour, seventh = match.groups()
    steps = SCALES[mode] if mode in SCALES else _unknown_scale(mode)
    if len(steps) != 7:
        raise ValueError("Roman numerals need a seven-note scale")
    degree = _ROMAN_VALUES[numeral.upper()]
    root = parse_note(key_root) + steps[degree - 1] + {"": 0, "b": -1, "#": 1}[accidental]
    minor = numeral.islower()
    if flavour in ("°", "o", "dim"):
        third, fifth = 3, 6
    elif flavour in ("+", "aug"):
        third, fifth = 4, 8
    else:
        third, fifth = (3 if minor else 4), 7
    notes = [root, root + third, root + fifth]
    if seventh == "7":
        notes.append(root + (9 if flavour in ("°", "o", "dim") else 10))
    elif seventh == "maj7":
        notes.append(root + 11)
    return notes


def voice_lead(chords: Sequence[Sequence[int]]) -> list[list[int]]:
    """Re-voice each chord after the first by the inversion and octave nearest the previous chord.

    "Nearest" is the least total semitone movement between the sorted notes (the distance of the
    mean pitch when the two chords differ in size), which keeps common tones still and moves the
    rest by step; it is what makes a block-chord loop sound smooth rather than leap.
    """
    if not chords:
        return []
    voiced = [sorted(chords[0])]
    for target in chords[1:]:
        previous = voiced[-1]
        best: list[int] = []
        best_cost = float("inf")
        for inversion in range(len(target)):
            inverted = sorted(target)
            for _ in range(inversion):
                inverted.append(inverted.pop(0) + 12)
            for octave in range(-3, 4):
                candidate = [note + 12 * octave for note in inverted]
                if len(candidate) == len(previous):
                    cost = float(sum(abs(a - b) for a, b in zip(candidate, previous, strict=True)))
                else:
                    cost = abs(sum(candidate) / len(candidate) - sum(previous) / len(previous))
                if cost < best_cost:
                    best, best_cost = candidate, cost
        voiced.append(best)
    return voiced


def parse_pattern(text: str, *, step_seconds: float, gain: float = 1.0) -> list[NoteEvent]:
    """Turn a pattern string into note events, one token per step of `step_seconds`.

    Tokens are separated by whitespace:

    - a note name with an octave ("C4", "Eb3", "F#5") starts a note;
    - "-" holds the previous note one more step (it is a tie, so "C4 - - -" is one long note);
    - "." or "~" is a rest;
    - "x2" or "x3" after a token repeats that token's step (x2 is the token twice, as two notes);
    - "|" is a bar line, ignored, only there so a pattern can be read.

    Raises on a hold with nothing to hold and on anything it does not know.
    """
    if step_seconds <= 0:
        raise ValueError("step_seconds must be positive")
    tokens: list[str] = []
    for raw in text.split():
        if raw == "|":
            continue
        repeat = re.fullmatch(r"x(\d+)", raw)
        if repeat is not None:
            if not tokens:
                raise ValueError("a repeat needs a token before it")
            tokens.extend([tokens[-1]] * (int(repeat.group(1)) - 1))
        else:
            tokens.append(raw)
    events: list[NoteEvent] = []
    for index, token in enumerate(tokens):
        if token in (".", "~"):
            continue
        if token == "-":
            if not events or events[-1].at + events[-1].duration != index * step_seconds:
                raise ValueError(f"hold '-' at step {index} has no note to hold")
            last = events[-1]
            events[-1] = NoteEvent(last.at, last.duration + step_seconds, last.midi, last.gain)
            continue
        events.append(NoteEvent(index * step_seconds, step_seconds, parse_note(token), gain))
    return events


def arpeggiate(
    notes: Sequence[int],
    *,
    start: float,
    step_seconds: float,
    steps: int,
    order: str = "up",
    gain: float = 1.0,
) -> list[NoteEvent]:
    """Play the notes of a chord one after another for `steps` steps, in a named order.

    `order` is "up", "down", "updown" (the top and bottom sound once per turn) or "alberti"
    (low, high, middle, high, the accompaniment figure that moves a chord without a melody).
    """
    ordered = sorted(notes)
    if order == "up":
        cycle = ordered
    elif order == "down":
        cycle = ordered[::-1]
    elif order == "updown":
        cycle = ordered + ordered[-2:0:-1] if len(ordered) > 2 else ordered
    elif order == "alberti":
        if len(ordered) < 3:
            raise ValueError("alberti needs at least three notes")
        cycle = [ordered[0], ordered[-1], ordered[1], ordered[-1]]
    else:
        raise ValueError(f"unknown arpeggio order {order!r}")
    return [NoteEvent(start + k * step_seconds, step_seconds, cycle[k % len(cycle)], gain) for k in range(steps)]


def beats_to_seconds(beats: float, bpm: float) -> float:
    """Seconds in `beats` beats at `bpm` beats per minute."""
    if bpm <= 0:
        raise ValueError("bpm must be positive")
    return beats * 60.0 / bpm


def loop_events(events: Sequence[NoteEvent], length: float, repeats: int) -> list[NoteEvent]:
    """Repeat a bar-aligned phrase `repeats` times, each copy starting `length` seconds after the last.

    A note that would run past `length` is kept whole, so its tail overlaps the next copy's start:
    that is how a looping score hides the seam. The caller renders `length * repeats` seconds, or
    a little more for the last tail; docs/MUSIC.md says why the loop point sits on a bar line.
    """
    if length <= 0 or repeats < 1:
        raise ValueError("length must be positive and repeats at least 1")
    return [
        NoteEvent(event.at + length * k, event.duration, event.midi, event.gain)
        for k in range(repeats)
        for event in events
    ]


def to_score_events(
    events: Sequence[NoteEvent], *, texture: str, gain: float, offset: float = 0.0
) -> list[dict[str, float | str]]:
    """Events in the shape tools/trailer/synthesize_score.py reads, frequencies rounded to 0.01 Hz."""
    return [
        {
            "at": round(offset + event.at, 6),
            "duration": round(event.duration, 6),
            "frequency": round(frequency(event.midi), 2),
            "gain": round(gain * event.gain, 4),
            "texture": texture,
        }
        for event in events
    ]


def _format_notes(notes: Sequence[int]) -> str:
    return " ".join(f"{note_name(note)}({frequency(note):.2f}Hz)" for note in notes)


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print scales, chords, progressions and pattern strings as note names and hertz.",
        epilog=(
            "examples:\n"
            "  music_theory.py scale A3 dorian\n"
            "  music_theory.py chord Am7 --octave 3 --inversion 1\n"
            "  music_theory.py progression C3 major 'I V vi IV' --voice-lead\n"
            "  music_theory.py pattern 'A3 - C4 . E4 - - .' --bpm 90 --steps-per-beat 2"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    commands = parser.add_subparsers(dest="command", required=True)

    scale_parser = commands.add_parser("scale", help="notes of a scale")
    scale_parser.add_argument("root", help="tonic with octave, e.g. A3")
    scale_parser.add_argument("name", choices=sorted(SCALES))
    scale_parser.add_argument("--octaves", type=int, default=1)

    chord_parser = commands.add_parser("chord", help="notes of a chord symbol")
    chord_parser.add_argument("symbol", help="e.g. C, Am7, F#m7b5")
    chord_parser.add_argument("--octave", type=int, default=3)
    chord_parser.add_argument("--inversion", type=int, default=0)

    progression_parser = commands.add_parser("progression", help="chords of a Roman-numeral progression")
    progression_parser.add_argument("key_root", help="tonic with octave, e.g. C3")
    progression_parser.add_argument("mode", choices=[n for n, s in SCALES.items() if len(s) == 7])
    progression_parser.add_argument("numerals", help="quoted, space separated, e.g. 'I V vi IV'")
    progression_parser.add_argument("--voice-lead", action="store_true", help="re-voice for smooth movement")

    pattern_parser = commands.add_parser("pattern", help="timed notes of a pattern string")
    pattern_parser.add_argument("text", help="quoted pattern, e.g. 'C4 - E4 . G4'")
    pattern_parser.add_argument("--bpm", type=float, default=100.0)
    pattern_parser.add_argument("--steps-per-beat", type=int, default=2)
    return parser.parse_args(argv)


def run(args: argparse.Namespace) -> list[str]:
    """The lines a parsed command prints; raises ValueError on a bad name."""
    if args.command == "scale":
        return [_format_notes(scale(args.root, args.name, args.octaves, include_top=True))]
    if args.command == "chord":
        return [_format_notes(chord_from_symbol(args.symbol, args.octave, inversion=args.inversion))]
    if args.command == "progression":
        chords = progression(args.key_root, args.mode, args.numerals)
        if args.voice_lead:
            chords = voice_lead(chords)
        return [f"{token}: {_format_notes(notes)}" for token, notes in zip(args.numerals.split(), chords, strict=True)]
    step = beats_to_seconds(1.0, args.bpm) / args.steps_per_beat
    return [
        f"{event.at:7.3f}s  {event.duration:.3f}s  {note_name(event.midi)}  {frequency(event.midi):.2f}Hz"
        for event in parse_pattern(args.text, step_seconds=step)
    ]


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        lines = run(args)
    except ValueError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
