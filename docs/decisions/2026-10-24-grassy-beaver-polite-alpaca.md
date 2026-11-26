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
  4242: one car in the street at her door at the arrival, none with the order the other way; both
  runs are kept in the evidence folder, `wrong-order-arrival-*` and `right-order-arrival-*`). The
  walking line waits for the shot (`HUD.hold_the_walking_line()`, `HUD.say_the_walking_line()`). A window
  that loses focus during the shot opens no pause over it, since the shot takes any key as its skip; the
  loss is remembered and the pause opens when the shot ends and play begins
  (`Main._focus_lost_in_the_shot`).
- **`CameraView.shown_by()`** (`src/world/camera_view.gd`): the world rect a camera shows (its viewport at
  its zoom, turned with the camera, centred where its limits hold it). `DayDirector` prepares the scenery
  round her with it and `Main` prepares the park's before the cut, after the shot has begun, so the
  shot's own camera is the one asked.
- **The tests**: `tests/test_opening_shot.gd` (the line over a hand-laid route, the rest, the pace,
  the hand-back, the skip), `tests/test_camera_focus.gd`, the HUD's held line in `test_hud.gd`, and
  `test_camera_start.gd`, whose assertion that the first frame after the title's press is on her now
  holds on the boot's frames and after the shot. Every suite that presses the title skips the shot the
  way a player does (`Boot.press_title()`, `Boot.skip_the_opening_shot()`).

## Picks, each open to the player's overturn

Two of them go beyond the player's words and are marked as such: 5 and 6.

1. **A retry skips it** (the item's proposal): the shot plays only from a title's start, so a retry and
   a resumed run start on her.
2. **Its length**: about a second on the park, five seconds along the whole route, constants on the
   class.
3. **Easy to take out, no flag**: one class, the focus and their wiring in `main`.
4. **The press that starts the run is never its skip**: the title starts the run two frames after the
   press, so that press is already spent when the shot begins.
5. **The walking line moves to the shot's end** (the design review's finding 12): the HUD holds day 1's
   walking line from the title's choice and says it when the shot ends. The player asked for nothing
   about the line.
6. **Focus lost during the shot opens its pause when the shot ends**, not over the shot: the shot takes
   any key as its skip, which a pause over it would also take. The player said nothing about the
   window's focus.

## What differs from the design

- The shot collides with M151, the record that the first frame after the title's disc draws within a
  tile of her (`tests/test_camera_start.gd`): on day 1's first attempt the frame after the title's press
  is now the shot's, while the boot's frames and the title still draw her doorstep, so that suite's
  assertion holds on the boot's frames and once the shot is skipped.
- The design had the hold start on the shot's first frame with the focus handed afterwards; the order
  is the other way round (above).
- `OpeningShot.line_for()` reads the junctions from `TutorialRoute.junctions()`, a copy of the
  route's own chain, and works none of them out itself.

## Not measured

How smooth the camera's path is: the bursts run at about 8 to 10 frames a second on a loaded machine,
so they show the path and not its smoothness, which is the player's run (`docs/review/`). The evidence,
her first step after the hand-back included, is `docs/evidence/grassy-beaver-opening-shot-2026-11-26/`.
