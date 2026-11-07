# Nappy — Music theory for the score

What the game's music will rest on. **The game has no music**: nothing here is installed, and
`project.godot` and `src/` know nothing of it. This is the reference a score is authored from, and
`tools/music_theory.py` is its helper: the definitions below as Python, so that a score is written as
names ("A dorian", "i VI III VII", a pattern string) and turned into the oscillator events that
`tools/trailer/synthesize_score.py` plays. Audio is synthesized from original oscillators, never
recorded (**sound-effects**), so a score is data and its WAVs are reproducible.

## Pitch and tuning

A note is a MIDI number: semitones, with A4 at 69 and middle C (C4) at 60. In twelve-tone equal
temperament the octave is divided into twelve equal semitones, so a semitone multiplies frequency by
2^(1/12) and `f = 440 * 2^((n - 69) / 12)` hertz. The helper's `frequency()` is that formula. Every
frequency in `tools/trailer/scores.json` is a note of it (1480.0 Hz is F#6's 1479.98 rounded by
hand), which `tools/test_music_theory.py` checks, so the trailer's hand-listed frequencies and the
helper agree on what each number means.

## Scales and modes

A scale is a set of pitch classes inside the octave, written as semitone steps above its tonic. Two
facts organize everything below.

- **The seven diatonic modes are rotations of the major scale.** Start the major scale's pattern on
  its second note and it is dorian, its third phrygian, its fourth lydian, its fifth mixolydian, its
  sixth natural minor (aeolian), its seventh locrian. `SCALES` in the helper holds them, and a test
  proves each is the major scale's rotation.
- **A mode's color is its one or two altered degrees against major or minor.** Compared with major:
  lydian raises the fourth (bright, floating), mixolydian lowers the seventh (open, plain, folk or
  rock), dorian is minor with a raised sixth (minor without gloom), phrygian is minor with a lowered
  second (dark, tense, Spanish), locrian lowers the fifth too and has no stable tonic chord (a
  diminished triad), so it is rarely a home key.

Besides the modes, the helper has the harmonic minor (natural minor with a raised seventh, which
makes the leading-tone pull of a dominant chord possible in minor), the melodic minor, the major and
minor pentatonic (five notes, no semitone, so almost any melody over them avoids a clash), the blues
scale (minor pentatonic with the flat fifth) and the whole-tone scale (six equal steps: no leading
tone, no home, a dreamlike drift).

**Choosing for this game.** The mother's day is a walk, so the score's job is to hold a mood under
a decision, not to ask for attention. Pentatonic and dorian or mixolydian material is the cheapest
way to stay pleasant under a looping figure, because few of their notes clash with a chord change.
Phrygian and the harmonic minor's raised seventh are for the pressure of a lethal carriageway or a
chase; whole-tone is for an unreal beat. Those are authoring suggestions, not recorded decisions.

## Chords and progressions

A **triad** stacks two thirds on a root: major (0 4 7), minor (0 3 7), diminished (0 3 6) and
augmented (0 4 8) semitones above the root. Adding a third third gives the seventh chords (major
seventh, dominant seventh, minor seventh, half-diminished), and a fourth a ninth. Suspended chords
replace the third with a second or fourth and so leave the major/minor question open, which is why a
sus chord suits a score that does not want to commit. `CHORD_QUALITIES` holds them as suffixes
(`""`, `m`, `dim`, `7`, `maj7`, `m7`, `m7b5`, `sus2`, ...), so `chord_from_symbol("Am7")` reads a
lead-sheet symbol.

**Chords of a key.** Stacking thirds on each degree inside a seven-note scale gives that key's seven
chords, named by Roman numerals: in major the triads are I ii iii IV V vi vii° (upper case major,
lower case minor, ° diminished). `diatonic_chord()` builds them by stacking, and `progression()`
reads a numeral string with the textbook rule: case sets the third, a suffix sets diminished,
augmented or the seventh, and a leading `b` or `#` shifts the root (so `bVII` in major is the major
chord on the flat seventh, a borrowing from mixolydian). Roman numerals make a progression
key-independent: the same string in another key is a transposition.

**Functions.** Chords fall into three roles that give a progression its direction: tonic (I, vi: home,
rest), predominant (ii, IV: leaving, building) and dominant (V, vii°: tension that wants the tonic,
because the leading tone and the fifth above both resolve into tonic notes). The common cycle is
tonic, predominant, dominant, tonic. Progressions that do the work in popular and game music:

| Progression (major key) | Reads as |
|---|---|
| I V vi IV | the pop loop; rises, falls back, no strong close, so it loops without a seam |
| I vi IV V | the fifties turnaround; ends on the dominant, which pulls back to the start |
| ii V I | the jazz cadence; the shortest complete tension and release |
| I IV V I | the plain blues-and-folk frame |
| vi IV I V | the same four chords started on the minor: a sadder loop |

and in a minor key `i VI III VII` (hopeful, an ascending loop), `i iv v i` (modal, no leading tone),
`i bVII bVI V` (the descending "Andalusian" cadence, ending on the dominant, so it pulls back to
the top). A loop that ends on the dominant or on a non-tonic chord asks for the next pass; one that
ends on the tonic sounds finished, so a looping score avoids it.

**Voice leading.** Chords played as blocks sound smooth when each voice moves the shortest way:
common tones stay and the others step. The helper's `voice_lead()` picks the inversion and octave of
each chord nearest the last, which also keeps the register from wandering over a long loop.

## Tension and release

Tension in tonal music is distance from a stable point, and release is the return. The levers a
score has, roughly from cheapest to dearest:

- **Harmonic function.** Dominant before tonic is the strongest pull; a deceptive cadence (V to vi
  rather than V to I) withholds the release; a half cadence (stopping on V) is a question.
- **Dissonance.** The tritone inside a dominant seventh (its third and seventh, 6 semitones apart)
  resolves inward or outward by step into the tonic chord. A diminished chord is unstable; a
  suspension (a held note from the old chord that clashes with the new one, then steps down) delays
  the release by a beat.
- **Mode.** A raised or lowered degree against the expected scale (phrygian's lowered second)
  reads as darker or more tense without any chord function.
- **Register and density.** A rising line, a thickening texture, more voices and a tightening
  rhythm raise tension without changing harmony; the reverse releases it.
- **Rhythm and silence.** A pedal (a repeated or held bass note) under changing chords stores
  tension; a rest before the tonic makes its arrival larger.

For a game that is about a route, the score's tension is something the player should be able to feel
change as the danger does, which is why the adaptive question below is the part that matters. The
repository's rule that a danger has one cue vocabulary (**cues**) applies to sound too: music may
set mood, and it does not become a second, unreliable warning.

## Rhythm, patterns and the helper's pattern strings

Tempo is beats per minute, a bar a fixed count of beats (four is the default); `beats_to_seconds()`
turns the two into time. A pattern string is the authoring form of a phrase:

```
A3 - C4 . E4 - - .
```

One token is one step. A note name starts a note, `-` holds it one more step, `.` or `~` is a rest,
`xN` repeats the token before it and `|` is a bar line for reading. `parse_pattern()` turns it into
timed note events at a step length, `arpeggiate()` spreads a chord over steps (up, down, up and down,
or the Alberti figure of low, high, middle, high), `loop_events()` repeats a phrase, and
`to_score_events()` writes the result in the `at`, `duration`, `frequency`, `gain` and `texture`
shape that `synthesize_score.py` reads. `uv run python tools/music_theory.py --help` lists the
command line, which prints a scale, a chord, a progression or a pattern as note names and hertz.

## Looping

A game score plays for as long as the player does, so every cue is a loop and the seam is the
craft.

- **Cut on a bar line, in whole bars.** A loop whose length is a whole number of bars at the tempo
  keeps the beat unbroken across the seam; the helper's `loop_events()` copies a bar-aligned phrase
  at its length.
- **Let a tail ring across the seam.** A note that would be cut off at the loop's end is kept whole
  and overlaps the first notes of the next pass, since a decay that stops at the seam is the click
  that gives a loop away. In a rendered WAV this means the render holds the tail wrapped onto the
  start (the overlap is mixed into the first samples), which is how a seamless loop file is made.
- **Start and end on stable material.** The cycle's last chord should lead to its first (the
  dominant-ended loops above), and a loop with a melody ends on a note the first chord contains.
- **Phrase length.** Four or eight bars is long enough not to be noticed as a repeat while a pass
  stays short enough to keep a WAV small; mixing two loops of different lengths over one another
  (a drone of seven bars under a figure of four) makes a combined cycle far longer than either.
- **A WAV loop cannot be seamless by accident.** A synthesized fade-in and fade-out, like the trailer's
  (`FADE_IN_SECONDS` and `FADE_OUT_SECONDS` in `synthesize_score.py`), belong to a one-shot, and a
  loop is rendered without them.

The release Web engine has no Ogg/Vorbis or MP3 decoder (`tools/web-template/README.md`), so a loop
ships as a WAV: uncompressed 16-bit PCM is large (a mono 48 kHz minute is a few megabytes), which
caps the number and length of loops more than the theory does.

## Adaptive music

Two ways to make a score follow the game, and a third that is no music at all.

- **Vertical layering** keeps one length and one tempo and fades *layers* (a bass, a pulse, a
  melody, a high shimmer) in and out with the situation. Every layer is in key and in time with every
  other by construction, so any subset sounds right; tension is added by adding layers or raising
  the intensity of the layers present.
- **Horizontal re-sequencing** switches between separate pieces (a calm loop, a tense loop) at a
  musical boundary, with a transition: a crossfade, a stinger, or a pivot chord common to both keys.
  It can change the tune completely and so costs more writing.
- **No adaptation** plays one loop per act. It is the floor, and it is what the first music should be
  until there is a measured reason to go beyond it.

**What this project's release engine allows.** Godot offers the layering natively as
`AudioStreamSynchronized` (several streams played in lockstep with a volume each),
`AudioStreamInteractive` (clips with authored transitions) and `AudioStreamPlaylist`. All three live
in the engine's interactive-music module, and the release Web engine is built with that module
stripped (`module_interactive_music_enabled=no` in `tools/web-template/profile.args`; the module is
listed in `tools/web-template/README.md` as restorable with a larger engine). So **the native route
is closed in the release build**, and re-enabling it means a rebuilt, larger Web engine.

**The way layering can work here is layered players synced by hand**, by these rules:

1. One `AudioStreamPlayer` per layer, each an `AudioStreamWAV` loop (WAV being the one format the
   release has).
2. Every layer is rendered at the same sample rate, the same length to the sample and the same
   tempo, so a restart realigns them; a layer is a different part, never a different length.
3. All layers are started in one call in one frame, and are never started or stopped to follow the
   game afterwards: **the volume is the control** (a bus or `volume_db` fade over a bar), so the
   layers never drift apart because none of them ever stops. A silent layer keeps playing.
4. The layers loop together by restarting all on the base layer's `finished` signal, or by giving all
   the same loop points, so a one-sample difference cannot accumulate.
5. A fade lasts a beat or a bar, and a new level is chosen on a bar line rather than mid-bar.

The cost of that route is one decoded stream per layer playing for the whole run (three or four
layers on a browser's mixing thread), and the reliance on players that start in the same frame
starting within one mix buffer of each other. **That has not been measured in this repository** and
is the first thing to prove with a short spike on the real Web export before a layered score is
authored: if a browser's start offset between two players is audible as a flam, the fallback is
horizontal re-sequencing between whole mixed loops, switched on a bar line with a short crossfade
(two players, the incoming one seeked to the outgoing one's position, which needs no lockstep), and
below that, no adaptation.

**What to adapt to.** The game's own state is already a small, honest signal: the act, the
nerves meter and whether a danger is telegraphed, hit or past. A score keyed to the act is cheap and
needs no layering (one loop per act); a layer keyed to nerves would let the score follow the
player's pressure; none of it may be the only warning (**cues**).

## Sources

Standard references the definitions above follow; no code from any of them is used.

- Open Music Theory (openmusictheory.com): scales, modes, triads and seventh chords, harmonic
  function, cadences, voice leading.
- Aldwell, Schachter and Cadwallader, *Harmony and Voice Leading*: functional harmony, cadences,
  suspensions.
- Wikipedia, "Equal temperament", "Mode (music)", "Chord progression", "Andalusian cadence", "Circle
  of fifths", "Pentatonic scale": tuning formula, mode rotation, common progressions.
- Karen Collins, *Game Sound* (MIT Press, 2008): looping, vertical and horizontal adaptive scoring in
  games.
- Winifred Phillips, *A Composer's Guide to Game Music* (MIT Press, 2014): layering, transitions and
  stingers in interactive scores.
- Godot Engine documentation, `AudioStreamSynchronized`, `AudioStreamInteractive`,
  `AudioStreamPlaylist`, `AudioStreamWAV`: the interactive-music classes and the WAV loop modes.
- `tools/web-template/README.md` and `tools/web-template/profile.args`: what the release Web engine
  strips.
