priority: bug

# snowy-hedgehog — A --walk with no rig to carry it is silently ignored · filed 2026-11-22

**Found** by the agent of pull request #1632 (minty-quail row 4b), reading back a run with `./tools/telemetry.sh`: the log shows no change of her position. The band `bug` is the filer's, open to the player's correction: a dev flag the project relies on breaks what `README.md`'s `--walk` row promises (a direction held for the whole run), found while finishing a refactor step.

**What holds.** `--walk` builds nothing on its own. The node that presses the keys, `AutoScreenshot` (`src/dev/auto_screenshot.gd`), is built only when `RunConfig.screenshot_rig()` is true, that is when a `--screenshot <path>` is given, or a `--frame-trace`, a `--frame-record` or a movie recording is bounded by `--after`. A `--walk` on any other command line is accepted by `tools/run.sh` and by the game, prints no warning, and leaves her on the doorstep for the whole run: the run log of the command below holds `start  doorstep (80,84)` and the same `walked into somebody at (80,84)` lines whatever the walk is (the same lines for `--walk 3n`, `3e`, `3s`, `3w` and `east`), and a `--quit-when-still` reading of (79,84).

**The command that shows it:**

    tools/run.sh --no-save --no-title --seed 4242 --day 6 --day-length 30 --force fire_truck 4 --walk 12n10e
    ./tools/telemetry.sh        # no blocked line, no path line, her tile never leaves the doorstep

The same flags with `--frame-record --after 25` added build the rig: the log then carries `blocked  pressed 0° for 1.0s at (80,82) without moving` lines at 1.6 s, 4.6 s, 7.6 s and so on. So `--walk` moves her when it is carried. The script in the report is also wrong for the doorstep, which `AutoScreenshot`'s header says is a notch with one exit: the first step, twelve seconds north, walks into the wall, and the next, east, into the other, so nothing in that script leaves the notch. That half is the script's, not the tool's, and is not part of this entry.

**What the fix must hold.** A `--walk` (and `--flee`, `--press`, `--tap`, which share the carrier) that no rig is built for is not accepted silently: the flag set is refused before the game starts with a message naming what it needs (cli-tools: a flag the run cannot honour is rejected, never turned into the wrong run), or the flag builds its own carrier and quits as a timed run does. `README.md`'s `--walk` row says what carries it. The check lives in the one place the flag list lives (`src/dev/dev_flags.gd`'s table, read live by `tools/lib_dev_flags.sh`), and `tools/test_cli_help.sh` or the suite for `RunConfig` holds a case for both paths.
