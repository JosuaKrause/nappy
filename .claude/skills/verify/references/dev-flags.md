# Dev flags, and why a plain screenshot is useless

Part of **verify**. Read it before planning a capture, a walk script or a rig run: it says what
each dev flag does to a run and which trap each one has. `src/dev/dev_flags.gd` declares the flags
and `README.md`'s "Dev flags" section documents them; this file is about using them to verify.

**A screenshot of a standing player is a screenshot of almost nothing.** The crowd and the events
are built around her, and the director only puts something in front of her while she is going
somewhere.

- **`--walk north|south|east|west`** holds a direction down for the whole run. `tools/shot.sh`
  forwards every dev flag. **From the doorstep, only south moves at all**: the home is a notch with
  one exit, cut into the south edge of its lot, so a rig walking any other way stands against the
  notch wall for the whole run — and its log looks exactly like a run. If a `--walk` rig is meant
  to meet something, check it actually travelled before reading anything else off the run.
- **`--walk 1s5e` and `--walk 3@45@2e`** walk a script of timed steps instead, left to right: one
  second south then five east, or three seconds at a bearing of 45° then two east. **A bearing is
  what a player's route actually looks like** — a press sets an arbitrary unit vector, so most
  headings are diagonal and a four-letter script can only reproduce the axes. Degrees run clockwise
  from north, and the pair of `@`s is a delimiter rather than decoration: a bearing's digits would
  otherwise run into the next step's. Every step presses both `move_*` axes at fractional strength
  through the same call the touch scheme uses, so the vector stays unit length and the rig walks at
  `Tuning.WALK_SPEED` (92px/s) — **a step must never press a vector shorter than one**, which is
  the rule `tests/test_touch.gd` holds for every input path. A malformed step fails the whole
  script rather than being skipped, because a script that silently drops one walks a different
  route than the one asked for. Three more shapes, for a trailer shot's path of several legs
  (`tools/trailer.sh`): a duration may carry a decimal point (`1.5s`); `p` stands still for its
  duration (`0.5p`), pressing nothing, the same as a player letting go; and an uppercase letter is
  that direction at a run (`2S`) rather than a walk.
- **`--smooth-walk`** turns a script's corners gradually, and is the one scripted press shorter than
  one: through a turn the press blends from one step's vector to the next, so her heading sweeps
  and her speed dips, and once the turn is over she is exactly where the abrupt script puts her
  on open ground (`WalkPlan`, `src/dev/walk_plan.gd`; `tests/test_walk_plan.gd` holds the end
  positions against a real `Stroller`). A wall, a stair flight or a shove from the crowd moves her
  differently on the two paths, and under `--walk` the abrupt script switches steps on process
  frames while the smooth one is pressed on physics ticks, so there the two agree to within a
  tick's walk; a recipe's `playback.smooth` presses both on ticks and is exact. It is pressed from the rig's physics tick, so it needs a script; a scene
  recipe asks for it with `playback.smooth`. No player's input path reads it.
- **`--flee [delay]`** turns round and runs when something starts chasing her. A rig that can only
  hold a direction can only ever demonstrate the *wrong* answer to a pursuit; the delay is the axis
  worth measuring — what the right answer costs when it is given late.
- **`--press <action> <seconds>`** pushes a real input event. Nothing in the suite or in a
  screenshot presses a key on its own, so a pause screen that never opens passes both.
  `Input.action_press()` sets the **polled** state and nothing else, which is right for `--walk`
  and useless for anything answered in `_unhandled_input`, so the flag pushes a real event with
  `Input.parse_input_event`.
- **`--press key:r 3.5`** — a bare key is not an action. `InputEventAction` reaches actions in the
  input map and nothing else, while a screen's own shortcuts are usually read as **keycodes**. The
  flag may be repeated, because one tap can only ever photograph one screen and what usually needs
  checking is a sequence. The one thing it cannot do: `R` reloads the scene and the reloaded scene
  re-presses, so a rig restarting the game loops for ever — read the boot lines rather than waiting
  for the PNG.
- **`--spawn corner:nw|ne|sw|se`** points the camera where two border bands meet. It stands a couple
  of tiles inside the corner, on the pavement — the dev rig's nearest-walkable search (`src/dev/dev_rig.gd`,
  the closest walkable point to a target) will otherwise happily leave her on the boundary
  carriageway.
- **`--after` is in seconds, not frames.** The windowed build draws ~110fps, so a frame count is
  quietly useless.
- **`--press snapshot_burst <seconds>` records a burst instead of a still** (PLAYTEST-56;
  woolly-finch 16). A still lands on a two-second turn, a stride or a wing beat by luck, and cannot
  establish that motion was smooth; the burst is the same rig with thirty-six frames over three
  seconds and a timing record, so **evidence about anything that moves is a burst, not a
  screenshot**. `tools/shot.sh out.png 10 --seed 4242 --spawn signal --layers 2,3 --press
  snapshot_burst 5` records from second five to eight and quits at ten; `tools/clip.sh` makes the
  video, and the **session-captures** skill says what is kept and what a frame may be said to prove.
- **`--invincible` keeps the day running so the capture can wait for its moment** (woolly-finch 17).
  A rig standing still at a busy junction pushes the meter to a hundred inside ten seconds, and a
  `--after 13` shot lands on the summary screen. Under the flag nothing ends the day, the clock
  never moves and the excitement meter never rises, so the light stays where the day started and no
  alarm flashes over the capture; a car or a hard fail does not end it either. So **any capture
  whose timing is hard to hit adds `--invincible`** and waits as long as it needs to. The HUD shows
  `INVINCIBLE` and the run log says so in its day header, which is what stops the picture being
  mistaken for a real run; a capture meant to show *cost* or a *loss* leaves the flag off, since a
  meter that cannot end the day answers nothing about either.

**Where a cue cannot be triggered on demand, relax its condition, look, and put it back.** The
screen-edge badge needs something lethal off-screen and closing, which is not something a six-second
screenshot can be asked for. Forcing it on for one shot is the only thing that finds a badge
colliding with the excitement meter or an icon squashed by a square box.
