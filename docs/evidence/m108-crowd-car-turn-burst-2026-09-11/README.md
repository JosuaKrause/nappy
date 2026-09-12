# M108, eight-direction entity graphics — the crowd car's mid-turn burst

The capture `docs/evidence/m108-crowd-cars-2026-09-11/README.md` names as missing: a car's own
turn, native scale, showing the intermediate diagonal views at entry, apex and exit with the debug
view's shadow (`2`) and bounding-box (`3`) layers on. One `tools/shot.sh` burst caught it, at
commit `c5860ee` (the tip of `origin/main` at capture time, descended from `09a5b94`, M108's crowd
car binding).

## The run

```
tools/shot.sh /tmp/turn-closure-1.png 8 --seed 4242 --spawn closure:0 --layers 2,3 \
    --press snapshot_burst 3
```

Kept whole at `rig-214034-seed4242-v0.8.2-624-gc5860ee/` (`run.log`, `maps/day01-attempt1.png`,
and `asked/burst-5482274-001/` with its 36 numbered frames, `burst.json` and the
`tools/clip.sh`-made `burst-5482274-001.mp4` beside it) — day 1, act 1, seed 4242, the day's only
closure `roadworks h(6,5)` (a horizontal street closed at block column 6, row 5).

**Why `--spawn closure:0` and not `signal`/`arterial` again.** The six tries recorded in
`docs/evidence/m108-crowd-cars-2026-09-11/README.md` stood at a signalled junction or the arterial
and waited for *some* car to pass and turn nearby; none did before the excitement meter — driven
by the crowd noise floor at those busy spots — ended the day, one capture as late as `--after 13`
catching the day-over screen instead. `main.gd`'s `_spawn_position()` puts `closure:<n>` at the
closure's own mouth, "the place the closure is supposed to be readable from" — every car that would
have used the closed street has to turn at that exact junction, so the odds of one turning inside a
short window are far higher than at a spot that merely sees ordinary traffic. `run.log` confirms the day's only closure
and the spawn point it produced: `TelemetryObserver` always logs the day's start position under
the fixed label `"doorstep"` (`src/telemetry/telemetry_observer.gd:258`) whether or not `--spawn`
moved it, and here it reads `doorstep (88,73)` — `--spawn closure:0`'s own position at the
closure's junction, not the home doorstep. The burst itself began 2.9s later, at `88,73`; a car
turned in view within the first second of it.

**Budget spent: one counted `tools/shot.sh` run.** A first invocation with the same flags failed at
boot with `Parse Error` on every class name (`GameEnums`, `DevFlags`, `EventInstance`, ...) because
this worktree had no `.godot/` import cache yet — gitignored, per `CLAUDE.md`'s "never commit
`.godot/`" — and produced no telemetry at all; running `./tools/check.sh` once built the cache, and
the run above is the first real attempt against a booted game. It is not counted against the
twelve-run budget, since nothing was checked and no window opened on a live game.

## Frame timing

`burst.json`'s `target_fps` is 12 (up to 36 frames over `BURST_DURATION_SECONDS` 3.0s), but the
actual per-frame gaps it records range from about 57ms to 130ms rather than a flat 83ms, and the
burst's own `duration_seconds` is 2.998198 for the full 36 frames — the timestamps below are those
recorded values, not the target.

- **Entry — `frame-0003.png`, elapsed 0.194s.** The car is axis-aligned: both the red strike box
  (layer `3`) and the cyan shadow capsule (layer `2`, `DebugLayers`' own `SHADOW_COLOUR` —
  `Color(0.32, 0.78, 0.95, 0.85)`) are upright rectangles running along the north–south
  carriageway, agreeing with an ordinary cardinal (front/back) picture. Frames 1–3 (0.041–0.194s)
  all match this.
- **Apex — `frame-0011.png`, elapsed 0.854s.** Box, shadow and picture are all rotated together to
  roughly 45°: the strike box is a diamond around the car's own diagonal artwork — a three-quarter
  view with a headlight and windshield corner drawn, not a cardinal texture simply rotated in
  place — and the cyan shadow capsule's own corners show past the car's opaque silhouette at the
  diamond's short ends, proving layer `2` is still live underneath the picture rather than hidden
  by it. Frames 4–11 (elapsed 0.267–0.854s, about 587ms) are the diagonal window, which lines up
  with `DECISIONS.md`'s M111 record of a 0.42s tightest quarter turn plus easing in and out of it.
- **Exit — `frame-0012.png`, elapsed 0.926s.** 71ms after the apex frame, box and shadow are both
  axis-aligned again, the picture back to the same cardinal view as the entry frames. Frames 12–18
  (through at least 1.450s) hold this, and the car keeps driving straight down the carriageway
  after that.

## What it shows, and what it does not

Across the eight intermediate frames the box and the shadow rotate continuously with the car's own
heading while the picture holds one fixed diagonal texture for the whole sector — exactly the split
`DECISIONS.md` records for this item ("the bounding-box layer already read the heading" against
"the picture runs side, diagonal, end through a turn with no code of its own"). Nowhere in frames
1 through 18 does the box or the shadow separate from the body, jump to a different rectangle, or
lag a frame behind the picture: **no defect seen** in this sequence — no jumped view, no shadow
floating off the body.

One thing worth naming plainly so a reader is not confused by it: day 1's own "Tap to walk, double
tap to run" tutorial banner is drawn across the lower third of the screen for the whole burst — the
game's ordinary first-day onboarding, not a debug artefact — and its text sits over the bottom of
the car in several frames. It does not touch the box, shadow or picture underneath it, but it makes
the sequence a little harder to read at a glance than a day with no banner would be.

This does not show a full 90° street-to-street corner — the car's entry and exit headings both read
as the same cardinal view, so what the burst catches is the near-side arc `DECISIONS.md` describes
turning the corner and rejoining, viewed from a fixed camera rather than a car crossing from one
street into a visibly different one. It is still the eight-direction system's own diagonal window in
motion, box and shadow included, which is what this item asked for.
