# Playtest 50 — First walk on the seal pictures and the new carets · 2026-09-09

Played on a local merge of the two open branches — M64, the eight seal pictures, and M93, the
caret chosen by expected impact — on seed 2295276695, day 5. Two screenshots were asked for with
`P` and one was taken by the game when the robber gave chase. The whole run folder is copied to
`docs/evidence/archive/session-captures/2026-09-09/run-163539-seed2295276695-v0.8.2-27-gc3305c2/`;
the pictures below are named inside it. The session also reviewed the M64 branch's files on
GitHub, and two of its findings are about those files rather than about play.

## 1. "what is shown here?"

`asked/016s-attempt1-asked.png`, 16 seconds into the day, standing on a pavement beside a removal
lorry with its ramp down.

> "what is shown here?"

**What was on the screen, read off the code and the run log.**

- **The amber wavy mark over the pram** is the baby's `UNSETTLED` cue (`Baby.Cue.UNSETTLED`, drawn
  from `baby_fuss.svg` by `Stroller._draw_baby_cue()`): awake and over the calm threshold, so
  sleepiness is frozen and the day is not progressing. It sits over the pram, and steps aside when
  the pram is behind her.
- **The yellow exclamation mark** is the alert over her (`Stroller._draw_alert()`): *this spot is
  about to be bad; move*. The log's cue line at 13.2s says why — *"a car, and she is in the road"*.
- **The glowing car** is a honking car's halo (M92): it is charging the meter, at 7.57 points a
  second on the debug HUD's `incoming` line.
- **The lorry with its ramp down on each pavement** is M64's `removal_lorry_pair`, a soft seal on
  a street off the day's route tree.

**The finding is that three cues on one screen needed asking about.** Whether the baby cue, the
alert and the halo are told apart on sight is exactly what a rig cannot answer; filed in M100's
open design questions.

## 2. "how do I know I stepped on the chalk and the robber is stuck inside the roof"

`auto/019s-attempt1-chase-alley_robbery.png`, taken by the game at 19 seconds when the robber came
for her. The chalk mark is the circle with two strokes at the alley's mouth; the robber is the
orange-haloed figure with the doubled red caret, standing in the dark band above the lower
building.

> "how do I know I stepped on the chalk and the robber is stuck inside the roof"

**She had not stepped on it.** The log's 18.2s entry — *contact: walked within 130px of the chalk
mark at (69,79)* — is the sight entry, written once when she comes within `CONTACT_SIGHT` of a
mark; a touch is within `ContactPoint.REACH` (36px) and writes a different entry, and none was
written before the day was lost at 21.0s. What a touch shows today: the mark's colour goes from
chalk white to pale green (`Palette.CHALK` to `CHALK_DONE`), and in a release build the status line
gains `somewhere out there: <task>`. In the debug build the `resistance ....` line is shown from
the moment a contact is on offer, and its dots move only when a perform is completed, so a
pick-up changes nothing on it. **So the acknowledgement is a colour change on a mark under her
feet and nothing else.** Filed in M100's open design questions, because the design's own rule is
that the resistance has no quest log, and how much a touch may say is the player's call.

**The robber is inside the building, and this is the reproduction M100's defect was waiting
for, with the cause.** Read off a headless probe of the same seed and day: the alley is rows
78–79, the mark at (69,79) is `ALLEY`, and the robber at (67,80) is `BUILDING`, one tile south of
the alley. The log has him at (67,80) at 13.3s, at 18.5s when he *"came for her"*, and at 19.2s
during the chase's telegraph, then 106–113px away at 20.6–21.0s while she was moving — a chase
step is clamped to walkable ground, so he never left the wall. The cause is
`ResistanceDirector._maybe_set_a_trap()`: the guard stands at a random bearing from the mark,
between 66 and 176px out (the robbery's `inner_radius` plus the mark's reach, to its
`pursues_within` plus the reach), and nothing asks whether that point is walkable. An alley is
64px wide, so most bearings land in the block. The dark band he stands in is the alley itself,
which reads as a roof in the picture: two findings in one sentence, the placement and the alley's
legibility. The placement is filed under M100 with this evidence; the alley's look joins the
question in section 1.

## 3. The rotated seal pictures are not valid images on GitHub

> "assets/events/burst_water_main_vertical.svg shows an error on github -- is it a valid image?"

> "same with assets/events/car_accident_vertical.svg"

> "all vertical ones have errors"

All three rotated files, and the older `assets/tiles/fence.svg`, carried a `--` inside an XML
comment, which the grammar forbids. Godot's importer forgives it, so the pictures booted and drew;
GitHub's renderer does not. Fixed on the M64 branch, and `tools/lint.sh` now parses every tracked
SVG so the shape cannot come back unnoticed. The record is in `DECISIONS.md` under M64.

## 4. The car accident's people are not the game's people

> "assets/events/car_accident.svg -- the people should look like people in the game -- those people
> do not look like it"

The onlookers were a circle and a rectangle drawn small. They are now `person.svg`'s own figure at
its own size in both accident files, upright in the rotated one too, because a person in this game
always stands upright. Fixed on the M64 branch; the capture is
`docs/evidence/shot-2026-09-09-seed4242-150985c-seal-car-accident-onlookers.png`. The record is in
`DECISIONS.md` under M64.
