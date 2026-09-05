---
name: verify
description: How to verify a change in this project — the three tools, what each one cannot see, the dev flags that make a screenshot worth taking, and the testing policy. Load this BEFORE committing anything, and BEFORE writing or changing a test.
---

# Verification

Run these before committing. They are fast and they each catch a different class of bug.

```sh
./tools/check.sh              # imports, boots the project, fails on any script error
./tools/test.sh crowd events  # just the suites your change touches, in seconds
./tools/lint.sh               # the governed docs, if you moved one
./tools/shot.sh out.png 3     # renders 3 seconds of real gameplay to a PNG
./tools/telemetry.sh          # what the last run actually did, in order
```

**The unfiltered `./tools/test.sh` is CI's job, not yours.** Every branch reaches `main` through a
pull request, and `main`'s ruleset requires the `test` check — which runs the doc lint, the boot
check and the full suite on the *merge result*. So the full run happens on exactly the tree that
matters, on a machine that is not yours, whether or not anybody remembers to ask for it.

**Which makes a local full run duplicated cost.** It is the slow thing in the loop by an order of
magnitude, and what it buys is an answer eight minutes before the PR gives the same answer about a
better tree. **A `PARTIAL RUN` marker is the expected state of a local run**, not a failure to
apologise for.

**Two cases where running it locally is still right**, and neither is a gate:

- **You changed the rigs themselves, or something every suite loads**, and want to know the blast
  radius before you push a red PR for everyone to look at.
- **CI came back red and you are iterating on the failure.** Reproducing locally beats pushing to
  ask a question.

**Do not quote a check count in a doc.** It changes on almost every milestone, and three files in
this repo once carried three different answers to that one question. Say what the command is, not
what it prints.

## What each one cannot see

**A green `test.sh` says nothing about whether a *run* behaves.** Every run writes an ordered trace;
if you changed anything the player experiences, **play a minute of it and read the log back**.
Defects found only that way include a `run` entry claiming a six-hundred-pixel event was "in reach",
and a meter breakdown reading `crowd 0.0, events 0.0` while the meter climbed, because the player
was doing it to herself with the run button and nothing said so.

**A green `check.sh` says nothing about whether the game looks right** — headless runs never call
`_draw()`. Real bugs found only by opening a screenshot: building extrusions overhanging every
sidewalk, zebra crossings rendering as visual static, a fire always spawning against the map wall.

**Where a run cannot be played, walk a rig and read the meter.** A throwaway `tests/test_zz_*.gd`
that prints numbers and is deleted before committing is the headless stand-in for the minute of
play, and the numbers it prints are how a balance constant gets **set** rather than derived. It is
the only thing that catches a pedestrian being ploughed along the pavement in permanent contact, or
a contact radius that leaves **no line to walk** on a two-tile pavement.

**A hand-built rig object can pass vacuously, three known ways.** A bare `Stroller.new()` has no
`CollisionShape2D`, so `move_and_slide()` never moves it — assert on `velocity`, not on position.
Its baby lookup is by child name, so a test's `Baby.new()` needs `name = "Baby"` set explicitly or
the awake query silently answers its no-baby default. And hand-built nodes want explicit `.free()`
calls, or the suite reports leaked instances under a green check count.

**A rig that steps the parts is not running the whole, and the gap is silent both ways.** When a rig
drives a subsystem by hand, ask what the engine was doing around it — and if the answer is "keeping
something bounded", the rig is not slow, it is wrong.

## Dev flags, and why a plain screenshot is useless

**A screenshot of a standing player is a screenshot of almost nothing.** The crowd and the events
are built around her, and the director only puts something in front of her while she is going
somewhere.

- **`--walk north|south|east|west`** holds a direction down for the whole run. `tools/shot.sh`
  forwards every dev flag. **From the doorstep, only south moves at all**: the home is a notch with
  one exit, cut into the south edge of its lot, so a rig walking any other way stands against the
  notch wall for the whole run — and its log looks exactly like a run. If a `--walk` rig is meant
  to meet something, check it actually travelled before reading anything else off the run.
- **`--flee [delay]`** turns round and runs when something starts chasing her. A rig that can only
  hold a direction can only ever demonstrate the *wrong* answer to a pursuit; the delay is the axis
  worth measuring — what the right answer costs when it is given late.
- **`--press <action> <seconds>`** pushes a real input event. Nothing in the suite or in a
  screenshot presses a key on its own, so a pause screen that never opens passes both. Note what its
  first version got wrong: `Input.action_press()` sets the **polled** state and nothing else, which
  is right for `--walk` and useless for anything answered in `_unhandled_input`. Push a real event
  with `Input.parse_input_event`.
- **`--press key:r 3.5`** — a bare key is not an action. `InputEventAction` reaches actions in the
  input map and nothing else, while a screen's own shortcuts are usually read as **keycodes**. The
  flag may be repeated, because one tap can only ever photograph one screen and what usually needs
  checking is a sequence. The one thing it cannot do: `R` reloads the scene and the reloaded scene
  re-presses, so a rig restarting the game loops for ever — read the boot lines rather than waiting
  for the PNG.
- **`--spawn corner:nw|ne|sw|se`** points the camera where two border bands meet. It stands a couple
  of tiles inside the corner, on the pavement — `_nearest_walkable` will otherwise happily leave her
  on the boundary carriageway.
- **`--after` is in seconds, not frames.** The windowed build draws ~110fps, so a frame count is
  quietly useless.

**Where a cue cannot be triggered on demand, relax its condition, look, and put it back.** The
screen-edge badge needs something lethal off-screen and closing, which is not something a six-second
screenshot can be asked for. Forcing it on for one shot is the only thing that finds a badge
colliding with the excitement meter or an icon squashed by a square box.

## Testing policy

Test what a screenshot cannot see, and screenshot what a test cannot judge.

- **Always tested:** meter arithmetic, falloff and the fairness contract, generator guarantees
  across many seeds, scheduler determinism, day outcomes, ending selection. These are the places
  where a bug is invisible until it ruins somebody's run.
- **Integration-tested against a real `City`:** anything about wiring — retirement, successors,
  scars. `tests/test_event_manager.gd` exists because a freed-node-left-in-a-list bug is invisible
  to a data-level test.
- **`tests/test_full_run.gd`** plays three seeds through all 14 days with time actually advancing.
  Keep it that way: a version that only *plans* each day leaves the mobile one-shots unfinished and
  the whole successor-and-scar chain untested while the test passes.
- **Not tested, checked by eye:** layout, colour, readability, whether a cue is legible from across
  a street.
- **A test asserting a relationship beats one asserting a value.** `intensity < walking decay`
  survives rebalancing; `intensity == 3.2` does not.
- **A test that only doubles the work of a change is deleted, not maintained.**
  *(2026-09-03: "this was one example of pointless brittle tests … they just double the amount of
  work when changing things".)* The shape is a test that **reads a design decision back to itself** —
  asserting `act_for_day(4) == 2` when `ACT_START_DAYS` is `[1, 4, 8, 12]` is the table restated, so
  moving an act boundary means editing the constant *and* editing the test, and no arrangement of
  those two numbers was ever going to disagree.

  **The distinction from a value that is worth pinning is the reason, not the literal.**
  `CAR_HORN_TIME >= required_horn_time()` also fails when somebody lowers the horn time — and that
  is the entire point, because it encodes *why* the number has a floor rather than what the number
  is. Ask which of the two a test would tell you if it went red: **"you changed a number"** is a
  test to delete, **"you broke the thing the number was for"** is a test to keep.

  Three that look prunable and are not: a **guard that a sweep was not vacuous** (`"there were cells
  to ask (%d)"`) is what stops a passing test from having checked nothing; an **ordering between two
  constants** survives every rebalance that respects it; and anything the incident list in this file
  names, which is a defect that has already shipped once.
- **A test that is true by luck is worse than no test.** Two have been found here — a determinism
  guarantee that stayed green because one seed happened to generate a different city, and a crowd
  predicate that asserted the wrong thing for eleven milestones. **If a test would pass with the
  code deleted, or passes only on the seed it was written against, it is not holding anything.**
- **An identity is not the property.** Asserting a relationship that is *true* but is not the
  condition the sentence beside it claims pins nothing.
- The suite must exit clean. **Leak warnings at shutdown mean a real retain bug.**

## When the suite prints nothing

**A test run with no output at all means an error in a suite, not a slow suite.** `run_tests.gd`
calls each suite's `run()` synchronously and then `get_tree().quit()`; an error aborts `_ready()`
before the quit, so the headless process sits there forever printing nothing.

**A parse error does the same thing and is easier to cause**, since `_discover` loads every suite
before running any: a bad indent in one file takes the whole run down with `Failed to load script`
and then hangs.

**The way to see either is to stop piping the run into `tail`** — `tail` prints nothing until EOF,
so a hung run and a silent one look identical. Redirect to a file and read it; the message is
usually on line four.
