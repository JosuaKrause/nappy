---
name: verify
description: How to verify a change in this project — the verification commands, experiment evidence retention, what each check cannot see, the dev flags that make a screenshot worth taking, and what a suite owes the runner. Load this BEFORE committing anything, running or changing a test, or collecting experiment evidence.
---

# Verification

- **Before committing: `./tools/check.sh`, `./tools/test.sh <the suites your change touches>`, `./tools/lint.sh` for a governed doc, `./tools/pycheck.sh` for `tools/*.py`.**
- **The unfiltered suite is CI's**, on the merge result; a local `PARTIAL RUN` is the expected state.
- **Headless unless the picture is the question**, and an agent's game run always carries a dev flag or `--no-save`.
- **A green suite says nothing about a run, the page or the picture**: play a minute and read the log back, open the screenshot.
- **A time a test reports is read from CI's run of the pull request, not a local one; a test-time optimization is compared locally while written and proven by CI's timings.**
- **Evidence about anything that moves is a burst, not a still.**
- **A suite leaves the shared state as it found it and never quits the tree, and an engine error fails the run.**
- **A check that compares a doc with the code is a `tools/` script in CI's `gates` job**, never an assertion in a suite.
- **Evidence a doc points at is committed under `docs/evidence/`, and kept compact.**

## Headless unless a window is the only way

**`check.sh` and `test.sh` already pass `--headless`, and nothing may take that away.**
`shot.sh` and `run.sh` are the two that open a window, and they are the exception you have to
earn: run one only when the thing being checked *is what the screen looks like*, and take the
smallest number of them that answers the question. A window opens on the player's screen and loses
focus the moment they do something else (woolly-finch 1), and a windowed run is bounded, never
free: it is slower than a headless check by however long Godot takes to boot a window and draw a
frame.

So: **never reach for a windowed run to check something a headless one can answer.** A rig that
prints numbers, an assertion in a suite, or a `check.sh` boot beats a screenshot for anything that
is not a picture. When a picture genuinely is the question, take it once with everything you need
already in the flags rather than iterating live.

**An agent's run always carries a dev flag or `--no-save`.** Every checkout and worktree of this
repository shares one `user://`, so the player's save is in reach of any game an agent starts.
`GameSave._uses_save()` already refuses a headless run and any run carrying a dev flag; `--no-save`
is what a flagless `tools/run.sh` session needs to say the same thing.

**A screenshot needs a display server, though not a visible window, and a run without one says so
and exits** (`[AutoScreenshot] nothing to photograph: this run is headless`). A missing screenshot
from an agent is a missing check, never evidence that the change is wrong. **Several rigs may run
at once**, windowed or headless, from different worktrees.

`references/windowed-capture.md` has the rest; read it before planning a capture and when one
fails. It says why a rig's window cannot hang, how a covered window is still photographed, what a
movie needs on top, and which failure each closing line of a failed capture names.

---

Run these before committing. They are fast and they each catch a different class of bug.

```sh
./tools/check.sh              # imports, boots the project, fails on any script error
./tools/test.sh crowd events  # just the suites your change touches, in seconds
./tools/lint.sh               # the governed docs, if you moved one
./tools/pycheck.sh            # ruff, mypy and the unit tests for tools/*.py, if you touched one
./tools/shot.sh out.png 3     # renders 3 seconds of real gameplay to a PNG
./tools/telemetry.sh          # what the last run actually did, in order
```

**The unfiltered `./tools/test.sh` is CI's job, not yours.** Every branch reaches `main` through a
pull request, and `main`'s ruleset requires the `test` check, run on the *merge result*. So the
full run happens on exactly the tree that matters, on a machine that is not yours, whether or not
anybody remembers to ask for it.

**Which makes a local full run duplicated cost.** It is the slow thing in the loop by an order of
magnitude, and what it buys is an answer minutes before the PR gives the same answer about a
better tree. **A `PARTIAL RUN` marker is the expected state of a local run**, not a failure to
apologise for.

**Every CI shard runs in a shuffled order, and a local run can too.** `tools/test.sh --shuffle SEED`
runs the chosen suites in an order drawn from SEED (a whole number): the same seed and the same
suites give the same order, and the runner prints `ORDER` (the seed and the order) and `REPLAY`
(a command that runs those suites in that order) before anything runs. `--repeat N` runs the
chosen suites N times in one process, each pass in its own order when `--shuffle` is given, and a
failure names its pass (`[pass 2/3] ...`); a repeated run's timings print as `pass K/N | suite  T ms`,
which the cost readers do not match, and `--record-costs` refuses `--repeat`. Both go with every
mode and change no shard plan: which suites a shard runs is the cost table's, only the order inside
its process is the seed's. CI's shards use the run's id as the seed, so an order dependence between
two suites shows on any pull request: **a shard that fails in CI is replayed by copying the `REPLAY`
line out of that shard's log** (it names the suites in the order they ran and needs no cost table),
or with `TEST_SUITE_COSTS=<the plan job's table> tools/test.sh --shard I/12 --shuffle <run id>`, the
line the shard's log prints first. An order-dependent failure is fixed in its own pull request, not
by pinning the order. `--repeat 2 --shuffle N` on a few suites is the cheap way to look for a leak
between passes (a `static var`, an autoload field) before CI does.

**Two cases where running it locally is still right**, and neither is a gate:

- **You changed the rigs themselves, or something every suite loads**, and want to know the blast
  radius before you push a red PR for everyone to look at.
- **CI came back red and you are iterating on the failure.** Reproducing locally beats pushing to
  ask a question.

## What `test` means on each kind of pull request

**What a green `test` says depends on the files the pull request changes**, sorted by
`tools/ci_classify.py` in CI's first job, never by the title:

- **On a pull request that touches `src/` or `tests/`, or anything that is not documentation**:
  every check ran and passed — the repository's consistency checks and every test of the game.
- **On a docs-only pull request** — every file Markdown or under `docs/`, none under `src/` or
  `tests/`, none of `docs/TELEMETRY.md`, `docs/COSTS.md` or `docs/ARCHITECTURE.md`, which the game's
  own checks read, and no `.gdignore`, which decides whether Godot imports `docs/` at all: every
  consistency check ran and passed, and the game's tests were skipped (bouncy-heron 20), since
  nothing they read changed. A pull request touching `src/` or `tests/` is never docs-only, so it
  never skips them.
- **On a queue update** — every file under `docs/todo/`, `docs/review/` or `docs/playtests/`: as
  docs-only, plus the queue update's mechanical checks.

**The two kinds of check are told apart by what a check is about, not by how long it takes.** A
test of the game — the boot check, the two runner fixtures `tools/test.sh` must fail on, the full
suite in shards, and the browser check, which exports the release build and plays it in Chrome —
is skipped on a docs-only pull request. A check that the repository agrees with
itself runs on every one, Godot or not: the doc lint, the CLI help test, the hook tests, the
agent-role test, the Python gate, the telemetry table's check (`tools/ci_telemetry_kinds.py`), the
cost table's check (`tools/cost-table.sh --check`, the one that needs Godot), and the pull
request's own checks, which read its files and its description:

- no file it adds is a handoff file (`tools/ci_no_handoff.py`);
- every inbox note it names on a `Filed from #N` line is the player's and is copied word for word
  into a playtest file it adds (`tools/ci_transcription.py`);
- on a pull request touching code, it resolves a queue item and files a record, or says `No queue
  item: <reason>` (`tools/ci_code_pr_queue.py`);
- on a queue update, it rewrites no playtest and deletes nothing open unaccounted for
  (`tools/ci_queue_update.py`).

**A new check that compares a doc with the code goes where a docs-only pull request runs it** — a
`tools/` script in CI's `gates` job, not an assertion inside a suite, which a docs-only pull
request never runs.

## What each one cannot see

**A time a test reports is read from CI's run of the pull request, never from a local one, bar the optimization case below**
(inbox #1307): a suite's duration, a case's own time, a check that holds a time bound. CI is where
a time matters, and a loaded machine makes the same case fail locally again and again, each
failure then explained in a report, a review and a description. A time bound is not asserted
locally: the timed cases of `tools/test_rules_hooks.sh`, `tools/test_codex_hooks.py` and
`tools/test_agent_identity.py`, and the wait_or_kill case of `tools/test_cli_help.sh`, assert their
bound only where `CI=true` (GitHub Actions sets it) and print the time as an information line
otherwise; a new timed check does the same, through one helper per script. A local run's time is
information, and a report or a review does not list it as a failure. **The rule is about tests, which are what CI measures**
(inbox #1307): while an optimization of a test's time (a suite's duration, the speed of the test
run itself) is being written, its versions are compared locally and in quick succession, since
CI's cycle is too slow for that, and the proof that it works is CI's timings, which are more
reliable than a local machine's; a builder reads them from the shard logs of the pull request's
run (`gh run view <run id> --log`), where the runner prints one `-- test_x.gd  N ms` line per
suite. A measurement of the game (a probe of the dawn's time, the crowd tick, a frame profile) is
outside the rule and is measured as its brief says.

**A green `test.sh` says nothing about whether a *run* behaves.** Every run writes an ordered trace;
if you changed anything the player experiences, **play a minute of it and read the log back**.
Defects found only that way include a `run` entry claiming a six-hundred-pixel event was "in reach",
and a meter breakdown reading `crowd 0.0, events 0.0` while the meter climbed, because the player
was doing it to herself with the run button and nothing said so.

**A green suite says nothing about whether the page starts.** The suite and `check.sh` run
headless, so they never meet the browser's keyboard events, its IndexedDB save or the Wasm runtime
the custom template builds. CI's `browser` job exports the release build the way the deploy does
(`.github/actions/web-browser-check`, which both run) and runs
`tools/web-template/browser-check.mjs` on it — the title, keyboard play, a day save and its reload,
day 2, days 8 and 14 booted by query, and the escape interior — so a commit that passes every
shard but cannot start a day on the page fails `test`, and the tag ruleset refuses to release it.
It cannot hear audio, plays no day at full length (day 1 is won through ordinary input from a
nearly settled baby, which reaches the summary and day 2, and days 8 and 14 are booted by query
rather than reached), and judges no picture: its screenshots, kept with `result.json` as the job's
artifact when it does not pass, are evidence somebody has to open.

**A green `check.sh` says nothing about whether the game looks right** — a headless run calls
`_draw()` and emits `draw` like any other, but its dummy renderer makes no pixels. Real bugs found
only by opening a screenshot: building extrusions overhanging every sidewalk, zebra crossings
rendering as visual static, a fire always spawning against the map wall.

**Where a run cannot be played, walk a rig and read the meter.** A throwaway `tests/test_zz_*.gd`
that prints numbers and is deleted before committing is the headless stand-in for the minute of
play, and the numbers it prints are how a balance constant gets **set** rather than derived. It is
the only thing that catches a pedestrian being ploughed along the pavement in permanent contact, or
a contact radius that leaves **no line to walk** on a two-tile pavement.

**A probe worth running again is parked in `tests/probes/`, not deleted and not left as a suite.**
The runner only discovers the top of `tests/`, so nothing there runs in the full suite or in CI;
it runs when named by path — `tools/test.sh probes/m64_density.gd` — and *measure it again
afterwards* then means running the same thing rather than reinventing it. Never park one on a
branch: a branch is invisible from the tree, and `git branch` should only ever answer *is there
work that is not on `main`*.

**A hand-built rig object can pass vacuously, three known ways.** A bare `Stroller.new()`'s
`move_and_slide()` moves it by the physics delta, which is 0 until a physics frame has run and one
tick after — assert on `velocity`, not on position.
Its baby lookup is by child name, so a test's `Baby.new()` needs `name = "Baby"` set explicitly or
the awake query silently answers its no-baby default. And hand-built nodes want explicit `.free()`
calls, or the suite reports leaked instances under a green check count.

**A rig that steps the parts is not running the whole, and the gap is silent both ways.** When a rig
drives a subsystem by hand, ask what the engine was doing around it — and if the answer is "keeping
something bounded", the rig is not slow, it is wrong.

## What evidence is checked in

**Every log, telemetry map or screenshot a doc points at gets copied into `docs/evidence/` in the
same commit as the sentence that points at it, and experimental evidence is compact by default.**
`references/evidence.md` says which artifacts of a playtest or a rig run are kept, what the
folder's README records and what an experiment checks in beside its conclusion; read it before
committing anything under `docs/evidence/`. In an agent's sparse worktree a new evidence file is
committed with `git add --sparse <path>`.

## Dev flags

**A screenshot of a standing player is a screenshot of almost nothing**, since the crowd and the
events are built around her while she is going somewhere: a capture walks (`--walk`), and from the
doorstep only south moves at all. **Evidence about anything that moves is a burst, not a
screenshot** (`--press snapshot_burst <seconds>`; PLAYTEST-56; woolly-finch 16), and **any capture
whose timing is hard to hit adds `--invincible`** (woolly-finch 17), unless it is meant to show a
cost or a loss. `references/dev-flags.md` has every flag with its trap; read it before planning a
capture, a walk script or a rig run.

## Writing a test

How a test is written — what it builds, what it mocks, what it holds — is **writing-tests**'s.

## What a suite owes the runner

- **A suite leaves nothing changed**: after every suite the runner compares the shared state with
  what it was before and fails the suite that changed it (`tests/shared_state.gd`; a `LEAK` line
  names the field). A suite gives back what it took; an exemption is a field with a reason, never
  a convenience.
- **A suite never quits the tree**, which ends the process and drops every later suite of the
  shard; code that quits is driven through a stand-in (`tests/route_rig_no_quit.gd`).
- **An engine error is a failed run, whatever the checks say**: `tools/test.sh` exits non-zero on
  `ERROR:`, `SCRIPT ERROR` or `Parse Error` in Godot's output, so bad input fed on purpose goes
  through a path that reports by return value (`JSON.new().parse()`, not `JSON.parse_string()`).
- **A run is read through `tools/test.sh`'s verdict and from a file, never through `tail`**: an
  error in a suite's own `run()` counts no failure, and `tail` prints nothing until the end.
- **`check.sh` puts back `docs/ARCHITECTURE.md` and `project.godot`** when its import pass rewrites
  them, unless you had already edited the file, which it names.

`references/runner.md` has the detail; read it when a run fails in a way these lines do not
explain, and before changing the runner or its fixtures.

## Proposed, not asked for

- **That a timed check asserts its bound only on CI** and prints the time locally is the filer's
  proposal, open to the player's correction (inbox #1307); the plainer alternative is the sentence
  alone, with local failures still reported.
