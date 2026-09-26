## M87 — A direction is not one of four · built 2026-09-07

Opened from a question rather than a complaint *(2026-09-07: "how does the telemetry handle
directions? also, is there a cli way to set the directions? it was only nswe before")*, and the
answer to both halves was that four was all there was.

**The cause is that M82 changed what a heading is and neither the log nor the rig followed.** Under
arrow keys a heading really was one of eight and four of those were the axes, so a four-way
vocabulary lost almost nothing. A press now sets an **arbitrary unit vector** —
`TouchControls.heading_to()` normalises the offset from her or from a focal point — so most headings
a player produces are diagonal.

**The log stops quantising rather than quantising more finely.** *(2026-09-07: "the telemetry
shouldn't quantize".)* Eight words was the obvious next step and is not the answer:
`TelemetryLog.compass()` writes the **bearing itself**, in whole degrees, so two headings a player
can tell apart are two readings in the log. Under the old rounding 44° logged `east`, 46° logged
`north`, and exactly 45° took the north/south branch because `absf(x) > absf(y)` is false — two runs
that went visibly different ways wrote the same word, and one run could change the word without
turning.

**The convention is stated where the number is written, because +y is south here.** The bearing runs
clockwise from north (-y) at 0°, through east at 90°, south at 180° and west at 270° — a real
compass reading. A bearing that does not say which way zero points is a number nobody can check.
`nowhere` stays for a genuinely zero vector: that is the absence of a direction, not a rounded one.

**The detection underneath was already continuous and was not touched.**
`TelemetryObserver._watch_direction()` compares real vectors with `angle_to()` against `TURN_ANGLE`
(120°) and eases the committed heading at `TURN_FOLLOW_RATE` (1.5/s). Only the noun was lossy, so
this is a formatting change.

**A `--walk` script step can name an angle.** *(2026-09-07: "the script should be able to specify
angles".)* `3@45@2e` is three seconds at 45° then two seconds east. The `@`s are a delimiter rather
than decoration: a bearing's own digits sit next to the next step's, and a letter is what already
ends a step's digits without a separator, so an angle needs one at both ends.

**Every step presses `TouchControls._set_axis()` at fractional strength, which is how one speed
survives.** A 45° step presses `move_right` and `move_up` at 0.707 each and the vector is unit
length, so the rig walks at `Tuning.WALK_SPEED` (92px/s) like everything else — a step that pressed
a shorter vector would reintroduce the slow walk M82 deleted, which
`tests/test_touch.gd`'s `_test_no_input_path_presses_a_vector_shorter_than_one` exists to forbid.
`_bearing_to_direction()` normalises on the way out so that holds by construction rather than by
trusting `sin`/`cos` to land on 1.0.

**The four letters are written as exact unit vectors rather than routed through the trig**, so
`1s5e` presses precisely one axis at strength 1.0 — bit-for-bit what a bare `--walk east` already
pressed. The M64 density figures and several evidence captures were taken with lettered scripts, and
a rig whose old scripts stop reproducing *exactly* is a rig that invalidates its own back catalogue.

**A malformed step fails the whole script rather than being skipped** — an `@` with no digits or no
closing `@`, an unknown letter, a duration of zero. A script that silently drops a step walks a
different route than the one asked for, which is the exact failure determinism exists to rule out.

**A drag and a double press still cannot be scripted at all.** They are the other two shapes the
scheme has, and `--tap X Y` remains a single synthetic touch fired at the start of the run. Left
open deliberately: the instruction named angles.
