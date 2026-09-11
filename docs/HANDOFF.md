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
load-bearing: a debug build is the only one where the URL modifiers answer at all.

A filtered run (`./tools/test.sh crowd events`) prints `PARTIAL RUN` and is not a green build.

**`check.sh`'s import pass rewrites two files that have nothing to do with the check, and `check.sh`
now puts them back.** It turns runs of spaces into tabs in `docs/ARCHITECTURE.md`'s file tree, and it
makes the editor rewrite `project.godot`, which loses more than whitespace — every `;` comment is
stripped and a setting can go outright, one run having taken `window/stretch/aspect="keep"`, which is
load-bearing for the presentation. `check.sh` records whether each was clean before it ran and
reverts it afterwards if it was, printing which file it reverted; the revert runs from an `EXIT`
trap, so it also happens when the check fails.

**A file you had already edited yourself is left alone and named**, because reverting it would delete
real work to fix a whitespace bug — that case still prints a note and is still yours to read with
`git diff`. **And `tools/export-web.sh` rewrites `project.godot` the same way with no such guard**,
so `git status` after an export is still the rule there.

**The game is published, and a push is a check while a tag is a release.**
`https://nappy.josuakrause.com/` serves it. `.github/workflows/ci.yml` runs lint, check and the full
suite on every push and every pull request; `.github/workflows/deploy.yml` fires on a `v*` tag and
nothing else — gate, export, upload, publish, in that order, so a red build never reaches the site.
It re-runs the gate rather than trusting CI, because both workflows fire on the same push and neither
waits for the other, and because a tag can point at any commit.

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
`assets/ui/pause.svg` rather than `_draw()` primitives.

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

**SVG-first style transfer is the graphics workflow.** The game selects native-size PNG
replacements where available; `--svg`, or `?svg=1` on the web, forces original SVGs.
The existing drawing transforms and animation remain in charge. Other families use SVGs.
Read [VISUALS.md](VISUALS.md) for reference roles and the replacement contract, and
M108, eight-direction entity graphics, M111, cars follow their turns, then M109, convert the SVG catalogue to PNG, in
[TODO.md](TODO.md) for the remaining work. Every PNG asset needs a corresponding SVG authored first.

**M76 is also built and released, on top of it.** Both the pause screen and the day summary carry a
continue button and a held restart that acknowledges the press before the day it starts blocks the
frame; the export publishes `index.js`, `index.wasm` and `index.pck` under a directory named for the
release tag, so Pages' unchangeable `Cache-Control: max-age=600` can no longer serve a **mixed**
build; and the shared card is opaque and declares its dimensions. The record is in `DECISIONS.md`
under M76 and M80. **Follow `TODO.md`'s own order for what is next.**

**The two milestones at the front of that order both overturn something on purpose, and each entry
says who did the overturning.** **M88** gives the two control schemes back to the player as a choice
— *asked for one scheme chosen nowhere on 2026-09-06 · overturned on 2026-09-07* — which is M82's
central decision going the other way, and the pieces it needs are recovered from that commit rather
than rewritten. **M89 and M92** draw a soft halo around whatever is currently charging the meter,
which the **cues** rule has refused since the vocabulary was written: *no circles around entities,
nothing draws a field.* That reasoning is about **danger** and it stands; the halo answers a question
the vocabulary never had an answer to — *which of the six things around her is pushing the number
up, and how much has each one actually cost her.* Its colour and its transparency both read the
points a source put on the meter over the last five seconds, traced from the meter's own sum —
colour linear to red at 40, transparency on a curve that makes a single point visible — and every
walker and car is a candidate on the same terms as an event. The numbers were set against one
played session on the branch and one capture each; the record is in `DECISIONS.md` under M92.

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
meter back*. If it still does not, the radii move next, not the density.

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
order is `TODO.md`'s.

- **M56 — the resistance is noticed.** What remains of its hunting rows is the roadblock, whose
  guards leaving their post is a posture drawing, and the end-on view the riot van now owes; its
  measurement against the nerves waits until act III is reached.

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
drives off the map except a car by the tunnel or the bridge. All of it was checked on rig captures
and one of it on a played branch; the record is in `DECISIONS.md` under M53.

## The queue, as prioritised on 2026-09-09

**`TODO.md`'s gameplay queue is the order, and it was set by the player item by item.** M56's
remaining hunting row, the roadblock, is next, on its own branch, and it is a drawing. M113, the
inspection, comes from playtest 55; M110, the crowd goes round a seal, follows. The debug view (`1` to `4` in a debug build, `--layers 1,3` for
a rig; `docs/TELEMETRY.md`, "The debug view") is how a field, a shadow or a body is checked by
eye, and every one of the three is now derived from the object's one `GroundShape`. Behind those, unordered: M96 (the teaching day and
the dog after it), M97 (calm areas that hold), M98 (pressure in the empty acts), M99 (the corridor's
density after the sealing) and M100 (the small work, the polish and the open design questions,
consolidated), with M105 (the city degrades), M106 (roofs, fronts and street trees) and M107 (the
run clock, hidden until an ending) placed in that batch provisionally, since the player asked
for them on 2026-09-10 without placing them.
Reaching act III — which M56's measurement against the nerves needs — waits until
that batch is done, and M101, the fire found before the engine, comes after that. SVG-to-PNG
style transfer is Codex's parallel track. Prepared artwork and its source-review sheets are listed
in `GRAPHICS.md`; the integration table in `TODO.md` assigns each family to its gameplay owner.
M110, the crowd goes round a seal, owns crowd blockage at seals; M111, cars follow their turns,
owns continuous turn paths and diagonal presentation. Coordinate them in the shared traffic code.

## What to distrust

What is untested by a human, listed so nobody mistakes arithmetic for a verdict.

- **The building exists and nobody has walked it.** `tools/run.sh --start-escape` (debug only;
  `--start-escape stairwell:left|stairwell:right|lobby|basement|floor:2|floor:1` boots into a
  part) puts her, carrying the baby, in front of her door on the third floor of a building with
  three hallways, two switchback stairwells at opposite ends, a barricaded lobby and a winding
  basement to the emergency exit — one map, the parts 64 tiles apart, every door a fade and a
  teleport. Everything about it is checked by a rig and by seven captures: whether a diagonal
  flight reads as *descending* when a sideways press walks it, whether the fade-and-teleport reads
  as a door or as a cut, whether eight rows a floor reads as a stairwell, and whether five floors
  is *"not excessively many"* are all played questions. The record is in `DECISIONS.md` under
  M112; what M102, the finale, still adds inside it is in `TODO.md`.

- **Every field has a shape now, and nobody has felt one.** A stationary body's field is a capsule
  about its own spine rather than a disc about its centre, and a moving thing's is an ellipse with
  the emitter at the rear focus: it reaches exactly as far ahead as its catalogued outer radius
  always did and less far behind and beside — a car at cruising speed (`e` 0.5) reaches a third of
  that behind it and half of it abeam. The café and the market stall bill from the tables to the
  middle of the carriageway (`inner_radius` 38, `outer_radius` 64, both measured from the spine) and
  no further; the roadblock, the protest, the burnt shell and the firefight lost their segment's
  half-length from both radii. The two eccentricity constants (`Tuning.FIELD_ECCENTRICITY_MAX` 0.7,
  `FIELD_ECCENTRICITY_SPEED` 260px/s) were set by design and checked against one rig picture,
  `docs/evidence/m61-field-after.png`. Whether a car going *past* still costs enough to notice,
  and whether a café at 64px still forces the crossing it was built to force, are played questions;
  `tests/test_balance.gd`'s relationships hold and the per-street probes moved within noise, but
  *is the day still losable on the meter* is asked by a rig only. The record is in `DECISIONS.md`
  under M61, the field.
- **Every shadow is drawn from a shape and every spread stands on a capsule, and nobody has looked
  at one in play.** A band-shaped shadow under a roadblock, a car's shadow along its own length, a
  swing frame's along its width; and a barricade, a roadblock or a construction band is solid as a
  48px-thick capsule rather than the disc it used to be, so she can stand closer to it along the
  street than before. The sealing and pavement guarantees are asserted over the capsule in
  `tests/test_shapes.gd`; whether a thinner body reads as *right* or as *a wall she can lean
  through* is a played question, and the debug view's bounding-box layer (`3` in a debug build)
  is the instrument to answer it with.
- **The city is walled off the path and nobody has walked it.** About 369 seal bodies a day stand on
  the 187 streets the day's tree does not use, and a day now plans four to five hundred events where
  it used to plan a hundred and thirty. Everything about it is measured and none of it is felt.
  **The specific worry, from a rig:** walking blindly away from the route on seed 2102613802, day 6
  meets a wall at the second street, cannot move for thirteen seconds, and loses the day at 17.6s
  with excitement at 100 — and the log says `crowd 28.0/s, events 0.0/s`, so it is the crowd shoving
  a stopped player, not the seals. A player who routes would not stand there. It is still the first
  time the wrong direction loses a day inside twenty seconds with nothing telegraphing it.
- **A wall with a gap in it is an invitation, and nobody has taken one.** A fraction of the day's
  soft seals lose one of their two bodies, so the street still looks obstructed and is walkable down
  the far side. The whole point is that a wrong turn stays open long enough to be taken and returned
  from — *"guide the player without having the player know they are being guided"* — and whether a
  half-open pair reads as an opening or as a barrier somebody forgot to finish is exactly the
  question the arithmetic cannot answer. The fraction is one constant and it is meant to move against
  a played day.
- **No day plans a route along the main road any more, and nobody has walked the city that makes.**
  Crossing the spine is untouched and free; running along it is refused when the tree is grown. The
  measured consequence is elsewhere and it is worth watching: the covering sets a one-shot is offered
  got **17 points narrower** — 45.7% of runs offered a single site before, 63% after — so an authored
  set piece is more often placed in one spot rather than on every route she might take. That is a
  fairness contract getting thinner, and it is a number rather than a complaint so far.
- **Every route the game plans is now grown on cells, and nobody has walked one.** The day's corridor
  is a chain of two-tile cells rather than a list of whole streets, so it can cut a corner through a
  park or take an alley — which is the point, and which also means the shape of a day's route is not
  the shape any played run has ever had. It is verified by the test rigs and by one dusk map read off
  a screenshot. **Whether a corridor that cuts through a park still reads as a route** is the
  question, and it is a played one.
- **No barrier is placed beside a calm area any more, and that is a third of the lattice.**
  `ClosurePlanner` refuses every access street of every calm area outright — a measured mean of 33.4
  of 264 streets a day. The intent is that a closure stops reading as broken; the risk nobody has
  looked at is the opposite one, that closures now cluster away from the places she actually walks and
  stop being met at all. The same trap the region doors carry, in a new place: *a nudge that
  removes the decision is worse than a closure that does nothing.*
- **The whole of the heat is unfelt.** Every number in it was set by design and checked by a rig:
  nobody has walked a city at full resistance progress, and the item that would tell you whether it
  is fair — measuring it against the five nerves — is the one still queued. It makes the back half
  harder *precisely for the player doing well at the optional path*, and **nobody has ever reached
  act III**. The night raid is the newest rung of it: on day 10 it hunts, and is lethal, only for
  a player holding every perform so far, and no run has reached day 10 with any.
- **An investigating patrol has never been seen.** The claim is that a police car breaking off its
  route to follow her reads as *being noticed*. That is a screenshot question and no screenshot has
  been taken.
- **The van's victim reads as a man standing next to a van.** A screenshot of the scene is in
  `docs/evidence/` and it is the weaker of the two taken: the figure is upright and unheld, so the
  whole of *being taken* is carried by it walking in and disappearing over 2.5 seconds, which a
  still cannot show and nobody has watched. The hunting half came out better — end-on, closing,
  and not comic.
- **Everything that comes at her now starts off screen, and nobody has watched one arrive.** A
  pursuer and a `TOWARD_PLAYER` row are sited past the edge of the view along the heading she is
  actually walking, plus 200ms of closing speed — 51px past the boundary for `cyclist` (165px/s,
  closing at 257 against her 92), 44px for `charging_dog` (130px/s, closing at 222) — and a
  `hard_fail` row goes further still so its telegraph ends before it arrives, which for the
  cyclist's 3.3s telegraph is 900px. **Two things a rig cannot answer.** Whether the screen-edge
  badge actually reads as *something is coming* for the whole of a longer approach, rather than as a
  mark that sits there — and **whether the day-3 dog still teaches running**, since it was
  deliberately sited too close to walk around and now is not. *"Unavoidability, if it is still
  wanted, has to come from somewhere other than siting it too close to see coming"* is written down
  and not built.
- **A biker can now end the day, and no biker has hit anybody.** The row declared `hard_fail` all
  along and could never fire it: `EventInstance.is_lethal_at()` refuses while the event
  `is_telegraphing()`, and the old siting delivered it in 0.78s against a 3.3s telegraph. It is real
  now, and *lethal on contact with a 33px band* has never been felt at the speed a bike travels.
- **A hunting van drives along the footway.** A pursuer steers straight at her over any walkable
  tile, which every pursuer in this game already does; this is the first time the thing doing it is
  a van. Whether that reads as menace or as a bug is a question for somebody watching it.
- **The difficulty has been felt by a human once**, and that was a verdict on one density pass and
  one act I. The sleepiness numbers, the nerve economy, and whether the arterial is crossable are
  all still arithmetic checked by `tests/test_balance.gd` and unfelt. **Nobody has ever got past day
  4**, so the whole of acts II–IV is seen by nobody.
- **Five nerves is a number nobody has played against.** It was raised from three after a run ended
  on day 3 — but two of those nerves went on a **defect**, so the number was raised against a
  difficulty that no longer exists.
- **A spoiled park is nine things and nobody has stood in one.** The coverage is measured — 91% of a
  courtyard, 99% of a four-block zone — and what is not measured is whether it reads as *the park is
  busy today* or as somebody having tipped an event budget into a field. It is also the one place
  where `EVENT_SPACING_SAME` does not apply.
- **The robber and the pacing man have never been met by a person.** The robber is the most
  mechanically complicated row in the catalogue — a field, a trigger, a notice, a stand-off and a
  break-off — and every number on him is a rig's. The pacing man is a man with no body on a 64px
  footway, avoided by the meter alone.
- **Every pavement obstacle moved this session and nobody has walked past one.** A stationary,
  unpinned body is now centred on the two-lane pavement band rather than standing at its lane's
  centre, and a spread on a north–south street is now laid along that street instead of across it. So
  `construction` genuinely blocks a 64px pavement — she needs 46px of clearance and the band gives 32
  — where before it left a free lane. That is the intent and it is also the first time an act I
  obstacle has been physically impassable in play. **Whether it reads as *cross the street* or as a
  wall dropped on the pavement is a played question**, and it is the one the sealing places about a
  hundred and fifty of a day, in eight kinds that nobody has walked past either.
- **A street that is solid has been walked by a rig and by nobody.** About two thirds of the
  catalogue has a body. The open question is not density but whether being stopped reads as *cross
  the street* or as an obstacle course. The gap between a kerbed van and the frontage is smaller
  than the pram, which is intended and is also the exact shape of *"no line to walk"*.
- **Most of the silhouettes have never been seen in play.** Only five are reachable before day 4.
  The two to distrust are the ones that are more than a picture: the **robber's two postures**,
  where the whole claim is that *waiting* and *coming* are told apart at an alley's length, and the
  **protest**, a 110px wall of bodies on a crossing.
- **A flock has been walked through by a rig and by nobody.** The gradient is measured — +35 through
  the middle, +8 eighty pixels off it, nothing at the rim — and it is the only row where the cost
  table and the thing the player meets are computed differently.
- **Calm ground is more than twice as fast as anybody has played it.**
  `SLEEPINESS_CALM_ZONE_MULTIPLIER` is 21 and a four-block zone fills the meter in **11.3s from
  empty**, against a 10.8s lap of one. That margin is what decides whether a day is winnable once
  the park is reached, and the last human verdict on the difficulty was given when the same
  constant was 12.
- **There is no audio at all.** Less urgent than it sounds: audio is redundancy, so the game must
  already be fully playable without it.
- **Nobody has measured the web build, only confirmed it runs.** It boots and plays at the live
  address; what has not been checked is frame rate at the game's scale on a machine that is not the
  one it was built on, and whether a stranger arriving at the page understands what it is.
- **The scheme a thumb actually drives has been walked once, and every part of it has moved since.**
  Playtest 33 is the one session on it, and it is what M85 answers — so the focal points are 120px
  out and 120px down from where that thumb met them, both circles are drawn where nothing was, a
  held finger re-aims where it did not, and the middle of the screen stops her where it used to
  steer her. **Four questions only a thumb settles.** Whether a drawn ring at `STOP_RADIUS` (48px)
  with a knob in it is read as *this is what is locked in* or as furniture. Whether a stop band
  nobody can see reads as a deliberate stop or as the game dropping an input. Whether the band and
  the two focus discs together take enough of the screen that ordinary aiming gets refused. And
  whether losing *tap her to stop* in joystick mode is felt as a loss at all, since the band is the
  same ground and the lesson no longer teaches either.
- **Nobody has chosen a mode, and the choice is now the first thing the game asks.** M88 offers
  joystick and tap on every device, so **tap on a phone and joystick on a desktop are both playable
  for the first time and neither has been played** — a thumb aiming from her own position across a
  whole phone screen is exactly the reach problem the two focal points were invented to solve, and a
  mouse driving a focal point is a hand that never had the reach problem being asked to use the
  answer to it. **The captions are the other half of it.** Two sentences on a title screen are all a
  first-time player gets to tell the modes apart, and whether *"aims from the nearer of two fixed
  points"* means anything before you have played either one is a question no rig can answer.
- **The restart path is guarded twice now and nobody has fumbled a tap at it.** A stray press after
  an ending can no longer begin a run just by landing anywhere, since only the two mode discs do
  that — but it can still land *on a disc*, so the 0.35s window (`TouchControls
  .DOUBLE_TAP_SECONDS`) that swallows a press right after a restart-triggered reload is kept rather
  than deleted along with the headline defect. **"Often" was the player's own word**, so what is left
  is a race with a much smaller target, and the window is still the thing to distrust in both
  directions: too short and an ending tap still reaches a disc, too long and a deliberate press
  feels ignored.
- **A phone held upright gets one rotation now, and nobody has held a phone since.** The three
  disagreeing rotations playtest 23 met are gone: one transform is applied to every `CanvasLayer`,
  the camera is no longer a second implementation, and the choice is re-asked every frame rather
  than on a `size_changed` that could arrive stale. The record is in `DECISIONS.md` under M60.
  **The one thing a rig cannot settle is the one that shipped three of those four symptoms** —
  `tests/test_orientation.gd` proves the input remap by construction and says outright that it
  cannot catch a sign error the transform and the drawing share. `tools/shot.sh` takes a resolution
  now, so the rotated branch can at least be photographed; it wants a person holding a phone.
- **The social card has been unfurled once, in a messaging app, and it failed.** The cause was the
  image's alpha channel — its transparent pixels carry RGB `(0, 0, 0)`, so a client that ignores
  alpha paints the card black — and the published copy is now flattened onto an opaque background,
  with its dimensions and type declared and a `twitter:image` beside the `og:` pair. **The fix has
  not itself been unfurled.** Paste the address into a chat client and see what comes back; the
  record of what was wrong and what was ruled out is in `DECISIONS.md` under M80.
- **There is no main menu.** There is a title screen — the doorstep with the traffic and the events
  running behind it — and it asks exactly one question: which of the two control schemes. Two
  circular discs with a caption each, and the hint under them reads `press a button to begin`. That
  is the whole of it: no options, no seed box, no load game. `WASD`, the arrows and `space` begin a
  run too and choose tap, and nothing on screen says so — deliberately, the same way nothing in the
  game names a key. **Nobody has met this screen on a phone**, so whether two discs and two
  sentences are enough to pick between schemes you have not played is unanswered.
- **A release build carries no modifiers, and nothing has confirmed that on a real release build.**
  `?telemetry=1` answers only when `OS.is_debug_build()` is true. The truth table is asserted in the
  suites, so the *predicate* is proven; the build type itself has no seam to fake and is therefore
  untested. **The deployed page is the first real check**, and what to watch is that it still starts
  and still logs nothing.
- **The city just got much cheaper to walk through and nobody has walked it.** Five barrier rows
  emit nothing at all now and the two that kept a field had their reach roughly halved, against a
  day that plans several hundred of exactly those bodies. **Whether the day is still losable on the
  meter** is asked by `tests/test_balance.gd` and answered by nobody. The opposite risk is the one
  to watch for: the complaint was that a quiet pavement never gave the meter back, and the failure
  this creates is a city that no longer costs anything to cross.
- **Four rows changed what they do to a player and all four were set by a rig.** `cat_dash` at 17
  and `loose_dog` at 32 are meant to land as a startle without becoming a day lost to something
  behind her; `chatting_mother` at a 48px `detain_radius` (with her 56px inner radius widened to
  hold it) and `cyclist` at a 33px lethal band are both meant to stop being walkable-past. The
  chatting mother's is the one to distrust: her capture reaches three quarters of the pavement
  band, **so no lane of her own pavement avoids her**, asked for twice by the player — at 26 and
  again at 33 — and felt at 48 by nobody yet.
- **The bollards are a placeholder drawing, and the border now refuses the crowd.** Five posts seen
  from above close each precinct mouth's carriageway, and the player has seen them and the
  T-junctions on a played branch. What nobody has watched is the crowd at the border since it
  became a wall: a walker or a car that reaches the boundary pavement turns or is clamped onto the
  map's last row, and the one body allowed out is a car on the spine by the tunnel or the bridge.
  Whether that reads as a city edge or as bodies bunching against glass is a played question.

## The rule that matters most before starting anything

**The first tool call of a design task is a search for the words, not a plan.** Grep `TODO.md` and
the playtest files for the noun. Three separate things in one session turned out to be already
written down and never built — the interact key (filed in playtest 02), the alley roulette, and M40
itself. The code is evidence of what was built; it is never evidence of what was agreed.

**And the second rule is that the plan is yours and the implementation is an agent's.** The
**orchestrating** rules load at the start of every session and say when that is not true.
