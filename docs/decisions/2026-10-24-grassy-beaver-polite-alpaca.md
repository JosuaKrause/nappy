# grassy-beaver — The opening shot, day 1's camera on the park and the way home · 2026-11-26

The item opening-shot of the entry grassy-beaver (a day one that teaches): the player asked, as an
experiment, for day 1's camera to rest on the close park, follow the intended path back to her door
and start, skippable (curly-moose #819), on day 1 only for now, the player making a few test runs to
see how it feels (minty-dolphin #834), with no cars spawning while the park shows so that none is
around when the camera comes back (minty-dolphin #867). Built from the design's section for the item.

## What was built

- **`OpeningShot`** (`src/day/opening_shot.gd`, flow layer): a node under `Main`, running while the
  tree is paused as the title does. A camera of its own (her zoom, turn and limits) cuts to the park,
  rests `REST_SECONDS` (1), moves along `line_for(route, doorstep)` (the park's centre, the junctions
  the tutorial route passes from its far end back to where it leaves the doorstep's street, the
  doorstep) over `TRAVEL_SECONDS` (5) at one pace, and is freed, which hands the view to hers. A tap or
  a key skips it; a held key's echo does not.
- **`CameraFocus`** (`src/crowd/camera_focus.gd`, a `CrowdFocus`): answers where the shot's camera
  looks; the crowd's box follows it for the shot's length. `StrollerFocus` takes over by itself when she
  is handed to the crowd at play's start (`WorldSimulation.meet_her()`).
- **`Main._play_the_opening_shot()`**, called from `_on_title_start()` for a fresh run whose day walks
  the tutorial (`_the_opening_shot_route()`): the focus is moved to the park and only then are the
  cars held (`Crowd.hold_new_cars()`), because the hold parks what is out of sight of the box's own
  centre; held first, a car at her door stayed in sight and kept driving unseen (measured on seed
  4242: one car near her door at the end, none with the order the other way). The walking line waits
  for the shot (`HUD.hold_the_walking_line()`, `HUD.say_the_walking_line()`); focus loss opens no
  pause over it.
- **The tests**: `tests/test_opening_shot.gd` (the line over a hand-laid route, the rest, the pace,
  the hand-back, the skip), `tests/test_camera_focus.gd`, the HUD's held line in `test_hud.gd`, and
  `test_camera_start.gd`, whose assertion that the first frame after the title's press is on her now
  holds on the boot's frames and after the shot. Every suite that presses the title skips the shot the
  way a player does (`Boot.press_title()`, `Boot.skip_the_opening_shot()`).

## Picks, each open to the player's overturn

1. **A retry skips it** (the item's proposal): the shot plays only from a title's start, so a retry and
   a resumed run start on her.
2. **Its length**: about a second on the park, five seconds along the whole route, constants on the
   class.
3. **Easy to take out, no flag**: one class, the focus and their wiring in `main`.
4. **The press that starts the run is never its skip**: the title starts the run two frames after the
   press, so that press is already spent when the shot begins.

## What differs from the design

- The design had the hold start on the shot's first frame with the focus handed afterwards; the order
  is the other way round (above).
- `OpeningShot.line_for()` derives the junctions from `TutorialRoute`'s public questions; the route
  class was not touched (another entry's files).

## Not measured

Her first step after the hand-back is not in the burst frames (the rig's walk does not move her until
play has begun); the evidence is `docs/evidence/grassy-beaver-opening-shot-2026-11-26/`.
