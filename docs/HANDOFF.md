# Handoff

**Where to pick up.** This file says what is true right now and what to do next. It holds no
history — that is [DECISIONS.md](DECISIONS.md), fetched when you need to know *why* — and no
progress-tracking, which lives there too.

**Read this, then [TODO.md](TODO.md).**

## The state of the tree

**Check `git status`, `git branch` and `git worktree list` for the current checkout and open work.**
Claude Code and Codex share `CLAUDE.md` and `.claude/skills/`; Codex reads `CLAUDE.md` directly
through `project_doc_fallback_filenames` in `.codex/config.toml`, and finds the skills through the
`.agents/skills` link. Its repository hooks need review through `/hooks` before they execute.

**Start with `git fetch --prune` and `gh pr list`.** Open pull requests may await review, checks or
merge permission. Resolve conflicts with `main` under the **merging-main** rules. A PR stays open
unless the user explicitly authorizes merging in the current session; enabling auto-merge and
delegating a merge require the same permission. Run `tools/queue.sh` for the order of the queue under
`docs/todo/`, and read `docs/review/` for the questions a playtest should cover; the player's original
reports and reference instructions live in `docs/playtests/`.

**Every branch is work in progress; nothing is parked on one.** The sealing measurement probes,
`tests/probes/m64_measure.gd` and `tests/probes/m64_density.gd`, live under `tests/probes/`, where
the runner does not discover them: they print rather than assert, they are the instrument the
per-street density figures in `TODO.md` were read with, and `tools/test.sh probes/m64_density.gd`
runs one by name.

**Work reaches `main` through a pull request and nothing else.** `main`'s ruleset requires one, plus
the `test` check — the doc lint, the boot check and the full suite, run on the merge result. So the
gate is CI's: locally you run `check.sh`, the suites your change touches, and `lint.sh` if you moved
a governed doc.

**Several PRs can be merged in a row without re-greening each one.** The ruleset does *not* require
a branch to be up to date with `main` (`strict_required_status_checks_policy` is off), so a PR whose
`test` check is green merges even after `main` has moved under it, as long as the merge is still
clean. A conflict still blocks it and still has to be resolved on the branch. **What that trades
away is real and worth knowing**: the check ran on that branch's merge result, not on the one it
actually gets, so a semantic conflict between two PRs that touch different files passes both gates
and lands broken. Watch `main`'s own CI run after a batch rather than assuming the last green PR
spoke for it.

```sh
./tools/test.sh          # the full headless suite, minutes — CI's job, not a local gate
./tools/check.sh         # boots the project, fails on any script error
./tools/lint.sh          # the governed docs, for sentences that go stale on their own
./tools/cost-table.sh    # rewrites docs/COSTS.md, what every event costs; --check is CI's gate
./tools/pycheck.sh       # ruff, mypy and the unit tests for the Python under tools/
./tools/run.sh           # plays it
./tools/serve-web.sh     # plays the *web* build, locally, in a browser
./tools/telemetry.sh     # what the last run actually did, in order
./tools/clip.sh          # convert telemetry bursts whose sibling MP4 is missing
./tools/reference.sh     # brings a real-world photo or video into docs/reference/
```

**B records an animation burst during desktop debug gameplay; P takes a single screenshot.**
Each burst keeps its numbered PNGs and actual frame times in its own `asked/burst-<id>/` folder
under the current telemetry run. `tools/clip.sh` uses ffmpeg to create `asked/burst-<id>.mp4`
beside it, preserving the frames. With no arguments it scans the whole telemetry folder for
finished bursts missing that video; pass a burst folder to select a particular sequence. Capture
targets three seconds at twelve frames per second and records achieved timing. See
[TELEMETRY.md](TELEMETRY.md#animation-bursts) and the session-captures skill for recording and
sharing motion evidence.

**`tools/reference.sh` is the only way a photograph enters this repository.** It shrinks a file
to fit inside the 1280x720 design box, strips every scrap of metadata, and takes the audio and
two thirds of the frames off a video. The second of those is a privacy guarantee rather than a
size one — the repository is public, and an untouched phone photo publishes the GPS coordinates
and the timestamp of wherever it was taken. See the **reference-photos** rule for what may not be
committed at all.

**`tools/serve-web.sh` is the only way to run the web build without deploying it.** A Godot web
export cannot be opened from `file://` — the browser refuses the WASM and pack fetches — so a static
server is the requirement rather than a convenience. It exports **debug** and serves `build/web`
over plain HTTP, printing an address rather than opening a browser, and the debug half is
load-bearing: a debug build answers every URL modifier as it stands, where a release page answers
only the ones `?debug=1` opens (`DECISIONS.md`, M193, the live page's ?debug=1 reaches the debug
flags).

A filtered run (`./tools/test.sh crowd events`) prints `PARTIAL RUN` and is not a green build.

**An engine error is a failed run, whatever the checks say.** `tools/test.sh` exits non-zero when
Godot's output carries `ERROR:`, `SCRIPT ERROR` or `Parse Error` — the words `check.sh` already
fails a boot on — in a filtered, serial, single-shard or locally sharded run alike, and shows the
offending lines. So a test that feeds the game bad input on purpose has to reach a code path that
reports it by return value: `JSON.new().parse()` rather than the static `JSON.parse_string()`,
which prints. `tests/runner_fixtures/engine_error.gd` raises one on purpose, runs only when named,
and CI requires it to go red.

**A suite that cannot load is a named failure, not a hang.** `run_tests.gd` checks a suite's
script with `can_instantiate()` before it instantiates it, prints `LOAD FAIL` beside the suite's
name, runs the rest and exits non-zero. The fixture for it is
`tests/runner_fixtures/unparseable_suite.gd.src`: it is never a `.gd` file in the tree, because
one script that does not parse breaks every `class_name` lookup in any engine start that has no
import cache yet, the atlas bake's included. `tools/test.sh runner_fixtures/unparseable_suite.gd`
stages the copy for that one process and removes it on exit, and CI requires the run to fail
within seconds. A suite whose own `run()` raises at runtime can still stop the runner short.

**`check.sh`'s import pass rewrites two files that have nothing to do with the check, and `check.sh`
now puts them back.** It turns runs of spaces into tabs in `docs/ARCHITECTURE.md`'s file tree, and it
makes the editor rewrite `project.godot`, which loses more than whitespace — every `;` comment is
stripped and a setting can go outright, one run having taken `window/stretch/aspect="keep"`, which is
load-bearing for the presentation. `check.sh` records whether each was clean before it ran and
reverts it afterwards if it was, printing which file it reverted; the revert runs from an `EXIT`
trap, so it also happens when the check fails.

**A file you had already edited yourself is left alone and named**, because reverting it would delete
real work to fix a whitespace bug — that case still prints a note and is still yours to read with
`git diff`. `tools/export-web.sh` puts `project.godot` back from a copy taken before the export
on every exit, since it stamps the file with the build's version and commit for the export's
duration, so the editor's rewrite never survives an export either.

**The game is published, and a push is a check while a tag is a release.**
`https://nappy.josuakrause.com/` serves it. `.github/workflows/ci.yml` runs lint, check and the full
suite as eight shards on every push to `main` and every pull request, a new push to a pull
request cancelling that pull request's older runs while a run on `main` is never cancelled; `.github/workflows/deploy.yml`
fires on a `v*` tag and nothing else — verify, boot check, export, upload, publish, in that order.
**The deploy does not run the suite again.** The `version tags` ruleset requires the `test` check
on the commit a tag points at, so a tag on a red or untested commit cannot be pushed, and the
deploy's first job asks the API for that check's outcome and refuses to build without it — the
same read `tools/release.sh` waits on before it tags.

**Cut a release with `tools/release.sh <major|minor|patch>`**, which reads the latest version tag and
prints what it would do. It only acts when given a second literal `push` argument, and it refuses a
dirty tree, any branch but `main`, a `main` that is not level with `origin/main`, and a commit that
already carries the newest `v*` tag — every refusal fires in the dry run too, so the dry run tells
the truth about whether the real thing would work. Semver, and **`major` is reserved for a change
that breaks or fundamentally alters the game**.

So pushing `main` no longer publishes. Completed work may be pushed without asking; see the
**committing** skill for what *completed* means. **Publishing is a separate, deliberate act**, and
the live site is whatever the newest tag pointed at — `git tag --list 'v*'` and `tools/release.sh`'s
own dry run say which.

**A fix on `main` is not a fix on the site, and that is the sentence to keep in mind before telling
anybody the page is well.** The site serves whatever the newest tag points at, so `git tag --list
'v*'` and `tools/release.sh`'s dry run are what say whether a given commit is actually out there.
A release has carried a game-ending bug before; the record is in `DECISIONS.md` under M73.

**A browser now goes back for a new release, and it did not before.** The export publishes
`index.js`, `index.wasm` and `index.pck` under a directory named for the release tag, because
GitHub Pages sends `Cache-Control: max-age=600` on everything with no header surface to change it —
under fixed names each file's ten minutes ran independently, so a reload could pair a fresh
`index.html` against the previous release's `index.pck`. **That means a stale report is now worth
believing rather than explaining away.** The record is in `DECISIONS.md` under M80.

## What to do next

**The game has two control schemes and the player picks one on the title screen, on every device.**
A press sets a direction she walks until the next press; a double press sets the direction and runs
it; **and a pointer held down keeps re-aiming**, continuously, locking in as it stands when it
lifts. Always at `Tuning.WALK_SPEED` (92 px/s): the heading is normalised on every re-aim, so
deflection distance means nothing and the deleted drag stick's slow walk cannot come back. No key is
named anywhere on screen.

**The two schemes are the two aiming origins, and everything else about a press is shared.**
`ControlsMode.Mode.JOYSTICK` aims from whichever of two fixed points — `TouchControls.FOCUS_LEFT`
(240, 480) and `FOCUS_RIGHT` (1040, 480) in the 1280x720 design box — is nearer the press, so a
thumb never has to reach across the phone to say *up*. `Mode.TAP` aims from her own world position.
**Neither is gated on the hardware**: `TouchInput.available()` now answers only whether the device
has touch, which is what routes a raw `InputEventScreenTouch` rather than an
`InputEventMouseButton`, and nothing else. A mouse can drive joystick mode and a thumb can drive tap
mode.

**Which doors into *stop* exist follows from the mode, not from the pointer.** In joystick mode a
press within `STOP_RADIUS` (48px) of either focus stops her, and so does **a band down the middle of
the screen** — 48px either side of the design box's centre line, not drawn — during a drag as well as
on a press, because the nearer focus flips the instant a finger crosses that line and the middle is
declared not-a-direction rather than damped. In tap mode a press within the same radius **of her**
stops her, which is the same reasoning seen from the other side: the aiming origin is her, so
pressing the thing you are steering is the obvious way to stop it.

**Both focal circles are drawn in joystick mode**, as a ring at `STOP_RADIUS` with a knob offset by
the heading currently locked in — centred reads as stopped, brighter and larger while `run` is held.
Tap mode draws neither, since a circle there would name a point that means nothing.

**Pressing one of the two title-screen discs is the only way a pointer begins a run**, which is what
makes an ending-screen tap unable to fall through into the next day rather than merely unlikely to.
`WASD`, the arrows and `space` begin a run too and choose **tap**, silently. `--controls
joystick|tap` and `?controls=` on a debug web build set the pre-title default a rig gets when it
skips the screen; that default is tap, so every existing capture and `--walk` script reproduces.

**The continue button, the held restart and the pause button are drawn on every device**, and a
press on one now reaches the screen underneath it: `ModeButton` sets `mouse_filter =
MOUSE_FILTER_IGNORE`, because Godot's GUI layer consumes a raw `InputEventScreenTouch` that lands on
a `MOUSE_FILTER_STOP` control and both screens read every press in `_unhandled_input()`. The restart
hold fills the disc itself as a radial sweep rather than a bar beside it, and the pause button is
the `ui/pause` picture rather than `_draw()` primitives.

**The keyboard still works and nothing on screen says so.** Arrows, `WASD`, `Shift`, `Esc`, `space`,
`R` and `Q` all press what they always did; no label, hint or teach line names a key, and the baked
`.tscn` defaults were cleared too so a scene file does not say one either. Quitting has no in-game
button on purpose — the window's own close button is its pointer route, and the web build has no
quit at all. The record for all of this is in `DECISIONS.md` under M83, and the session it came from
is [PLAYTEST-29.md](playtests/PLAYTEST-29.md).

**What is gone and is not coming back is the two *mechanisms* M82 deleted**, as opposed to the
choice between schemes, which M88 gave back: the drag stick, the aimed joystick playtest 27
specified and never built, the `RUN` button, and a tap that walked her to a **destination**. The
last of those is the load-bearing one — *a tap that pathfinds hands the route decision to the
game*, and the route decision is the whole design. The records are in `DECISIONS.md` under M82 and
M88.

**SVG-first style transfer is the graphics workflow.** The bake puts the native-size PNG
replacement on the page where one exists and the SVG's raster where none does;
`tools/bake-atlases.sh --svg` bakes the original SVGs for a local comparison, and nothing at
runtime selects a mode. The authoring sources live in `art/`, which the engine ignores.
The existing drawing transforms and animation remain in charge.
Read [VISUALS.md](VISUALS.md) for reference roles and where the pictures live, and
M109, convert the SVG catalogue to PNG, in
[TODO.md](TODO.md) for the remaining work. Every PNG asset needs a corresponding SVG authored first.
Compare each character's directions, gait frames and state variants as one family; the
illustrated-PNG skill describes the identity references and extraction checks that keep them aligned.

**M76 is also built and released, on top of it.** Both the pause screen and the day summary carry a
continue button and a held restart that acknowledges the press before the day it starts blocks the
frame; the export publishes `index.js`, `index.wasm` and `index.pck` under a directory named for the
release tag, so Pages' unchangeable `Cache-Control: max-age=600` can no longer serve a **mixed**
build; and the shared card is opaque and declares its dimensions. The record is in `DECISIONS.md`
under M76 and M80. **Follow the order `tools/queue.sh` prints for what is next.**

**The rule playtest 27 raised alongside the joystick is now also enforced by a test**: *"there is no
way to walk slowly — that is intentional — there should only ever be one speed (plus a second via
running)"*. `Stroller` moves toward `input_dir * top_speed` with the raw input vector, so the drag
stick's partial deflection was the one input path that could walk her at anything other than
`Tuning.WALK_SPEED` (92 px/s) — and every pursuit lead time in `src/autoload/tuning.gd` is computed
against 92 as *the* walking speed. Deleting the drag stick is what makes the rule true, and
`tests/test_touch.gd`'s `_test_no_input_path_presses_a_vector_shorter_than_one` is what keeps it
true.

**The most useful thing anybody can do now is play a day on the new controls, then play a whole run
on the layers under it**, and none of the following has been touched by a thumb since M83 landed.

**Playtest 25's nine findings are all built and none of them has been walked.** The barrier rows
stopped charging the meter, two ambient reaches were cut roughly in half, the cat and the dog hit
harder, two rows that could be walked straight past now catch you, and alleys are walled at 15% of
the rate they were. That is the largest single change to what a day costs the project has made, and
it was measured against a rig rather than felt. The record is in `DECISIONS.md` under M73, M74 and
M75. **Its own test is the player's sentence**: *walking a seemingly empty pavement has to give the
meter back*. It now does, and visibly: a quiet street nets about 3.8/s downward with the day's own
crowd on it, a full meter in a little over twenty-five seconds. The lever that got there was the
**walking decay** and not the crowd's radii, which are untouched — `DECISIONS.md`, M117, excitement
decays visibly on quiet ground, has the before-and-after and the ceiling the number is up against.
Whether it *reads* as recovery rather than merely measuring as it is a question for a person, and
it is under `docs/review/`.

**Playtest 22's findings are built and unwalked underneath that** — the sealing that closes the city
off the path, the trunk that keeps the doorstep joined to it, the ban on routing along the main
road, and the thinning that leaves a wrong turn open. Its questions are the kind only a person
answers: *does a walled city read as a route decision or as a maze*, *is a thinned wall an
invitation or a mistake*.

**Read [PLAYTEST-25.md](playtests/PLAYTEST-25.md) first, then [PLAYTEST-22.md](playtests/PLAYTEST-22.md),
[PLAYTEST-21.md](playtests/PLAYTEST-21.md) and [PLAYTEST-20.md](playtests/PLAYTEST-20.md).** Playtest 25 is the first
phone session on the built mobile game and the first human verdict on the sealed city. Playtest 21
is a brief run whose complaint — the city *"feels way empty"* — the sealing answers. Playtest 20 is
the full seven-day run behind them, and its findings are filed against the milestones that own them.

**Read `DECISIONS.md` under M69 before touching routes, closures or the corridor**, because it
changed the ground every one of them stands on. Reachability is now `ReachabilityGrid` — the tile map
contracted into two-tile cells, one node per connected component of a cell's walkable tiles — the
day's route tree grows on it, and `ClosurePlanner` refuses a calm area's access streets outright.
`StreetNetwork` is still there and still owns the lattice and the structural route count; it is no
longer what answers *can she get there today*.

Two of the queue's milestones carry state worth knowing before picking them up; their place in the
order is the band in their own entry.

- **M56 — the resistance is noticed.** What remains is its measurement against the nerves, which
  waits until act III is reached.

**The instrument to judge any of it with now exists and was used this session.** The dusk map draws
the walk over the plan: where she went, which stretches she ran, and which events actually reached
her, against the corridor the day expected her to take. `docs/TELEMETRY.md` says what it draws.
Playtest 20's evidence is fourteen of them, one day and one dusk map for all seven days of a run —
read alongside the run's own log, they are what turned "barriers don't work" into the specific,
citable numbers now in `TODO.md` (the day-4 `charging_dog` killing her in 0.8s against every other
encounter's 1.5s; the chalk mark going unfound on all four days it existed, `resistance 0/4`). **A
rig can walk a route now**, so a picture of a specific route is cheap: `--walk` takes a script of
timed steps — `--walk 3s15e` is three seconds south then fifteen east, and `--walk 3@45@2e` is three
seconds at a bearing of 45° then two east — and the same script on the same seed walks the same way
every time. **The bearing form is the one that reproduces a route a player would actually walk**,
since a press sets an arbitrary unit vector and most headings are diagonal; the run log writes the
bearing in whole degrees for the same reason.

A junction is made of the streets that actually meet at it: a precinct's end, the city's border
and the spine's side arms all read as what they are — a T with a line of bollards, a T with no
zebra running into the mountain, four dotted crossings under one light — and nothing walks or
drives off the map, or onto it, except a car by the tunnel or the bridge. All of it was checked on rig captures
and one of it on a played branch; the record is in `DECISIONS.md` under M53.

## Where the last session stopped, 2026-09-26

**This section is the pick-up for the next session and is replaced by it.** Fetch first; PR state,
checks and worktrees can move independently of this file.

- **The player's order is done**: the `git grep` guard, the queue as files (M223), every open PR
  converted, the counter's asks (M225, with all counting on `nappy.goatcounter.com`) and the
  release that carries them, v0.19.0. "then we can do regular work again." The queue is what
  `tools/queue.sh` prints; its `now` band is M227 (Codex works as a sub-agent of a Claude Code
  session, in a worktree), M226 (the pursuing dog keeps its day-3 timing, and the other warnings
  fit it) and M223's open item (the overhaul of every entry and review item).
- **After the release**: read the counter back as `docs/review/2026-09-26-after-the-next-release-read-the.md`
  says. The page visit is listed as `/nappy.josuakrause.com`; a path starting `/nappy` is a visit, a
  name starting `nappy-` is a game metric.
- **Open pull requests, all on the queue-as-files layout, none reviewed for its own work yet**:
  - **#362, M137, the trap comes to her**: built. Its record is named
    `2026-09-25-M137-the-contact-…`; `tools/queue.sh` counts an entry closed only through a record
    named for it, so rename it `2026-09-13-M137.md` (`tools/new-name.sh decision --entry M137`
    writes that name) or M213's `after:` on M137 fails the lint once it merges. Its conversion
    review also flagged the record and `docs/EVENTS.md` disagreeing on which trap variants use the
    robber's chase.
  - **#365, M203 and M216, roofs**: built and green; it has to delete M216's queue folder, which is
    still open on `main`. No pictures yet (`tests/probes/m216_evidence.gd` computes seeds and walks).
    A front facing the map's edge happens only on a cul-de-sac's dead end; that goes to the player
    before the special case is kept or dropped.
  - **#379, M205, the man shouting** (draft): the note handover's 2.5s stand is the orchestrator's
    proposal; his zero charge on an ordinary day did not reproduce. Not reviewed.
  - **#385, the scenery animation plan** (draft, plan only): its plan is M159's item
    `separate-scenery-animation-from-static-ground.md` and its measurements are in
    `docs/evidence/entity-performance-2026-09-26/`.
- **Branch `fix/spent-park-followup`, no PR**: M129's item "a fence carried into the next days keeps
  two calm areas on the route tree" holds the plan; the branch has only an unrun start of its
  regression test. The player: "plan the fix but we need to focus on other tasks right now".
- **Merge permission**: the player said "merge the PRs as needed" in this session; a new session
  confirms it before using it. A release needs its own go-ahead.
- `.claude/briefs/` holds the brief of every branch worked this session, with every amendment;
  start fresh agents from them rather than resuming this session's.

## The queue

**`tools/queue.sh` prints the order, from the band each entry carries** (`now`, `next`, `later`,
`parked`, in its `README.md`'s opening lines); the player moves an entry by changing its band.
Playtest 66's four milestones are built and released (`DECISIONS.md`, M119 to M122); what only a
walk can judge about them is under `docs/review/`. M56 has only its measurement against the nerves
left, and that waits for act III, after M99 (the corridor's density after the sealing) and M100
(the small work, the polish and the open design questions). The debug view (`1` to `5` in a debug
build, `--layers 1,3` for a rig; `docs/TELEMETRY.md`, "The debug view") is how a field, a shadow, a
body or the day's routes is checked by eye, and every one of them is derived from the object's own
`GroundShape` — one apiece for everything but the car crash, which is solid in two pieces
(`DECISIONS.md`, M118). SVG-to-PNG style transfer (M109) is Codex's parallel track; prepared artwork
and its source-review sheets are listed in `GRAPHICS.md`, and M100's entry carries the art that waits
for its gameplay owner. The crowd goes round every solid body it meets (`DECISIONS.md`, M110), and a
car follows an arc through a turn with its heading continuous throughout (`DECISIONS.md`, M111),
drawn through side, diagonal and end views (`DECISIONS.md`, M108, the crowd car); a street
about-face crosses the kerb by design (`DECISIONS.md`, M111, the kerb overhang stays).

## What to distrust

**What nobody has played is listed in [REVIEW.md](REVIEW.md) and the items under
[review/](review/), not here.** Every item there is something a rig has measured and a person has
not felt, with what to look at and the question a run answers; a playtest closes the items it
covered. Read it before asking for a playtest, and
add to it before merging work that only a person can judge.

## The rule that matters most before starting anything

**The first tool call of a design task is a search for the words, not a plan.**
`tools/decisions.sh --in all <noun>` searches the queue's entries, the records, the review items and
the playtest files. Three separate things in one session turned out to be already
written down and never built — the interact key (filed in playtest 02), the alley roulette, and M40
itself. The code is evidence of what was built; it is never evidence of what was agreed.

**And the second rule is that the plan is yours and the implementation is an agent's.** The
**orchestrating** rules load at the start of every session and say when that is not true.
