# minty-quail's end remeasure: pictures of what a step changed on purpose

**Claim.** Each picture below is what one behavior that a refactor step of minty-quail changed on
purpose looks like on head, taken windowed with the repository's own capture tools. Where the old
behavior can be staged with the same flags, the same capture is beside it from v0.29.2. Nothing is
judged: a picture is listed with what it shows and what it cannot show.

**Limits.** A capture is dated runtime evidence of one build, seed, route and presentation
state, never an approved visual reference (session-captures). Every capture carries
`--invincible` unless it is a loss or an outcome screen, so a HUD that says INVINCIBLE is not a
played run. A burst has 36 frames over about 3.0 s, so its frames are 81 to 84 ms apart (median per
burst; the widest single gap is 190 ms), about two and a half physics ticks; `raw/burst-*.json`
holds each used burst's frame times.

**Revisions.** Head is `47e4654388004cb1ee9bc0f52a676f4d8b2e0013` (main when the captures were
taken; the last code change on it is `f98443b5b19ddada1899c13c4d939d84049ea453`, since the
commits after it change docs only). The before tree is the tag v0.29.2
(`094536ab0a34842aa4dfd523dde2191d8c6814e5`), a detached worktree made with
`tools/agent-setup.sh --detach v0.29.2 mq-r4-old` and removed after with `--remove`. Godot is
`/Applications/Godot.app/Contents/MacOS/Godot` 4.7.2. One run on head carries a `-dirty`
version suffix (the cat's), because the evidence folder was already in the tree; no file under
`src/`, `tests/` or `tools/` changed.

**Commands.** Stills: `tools/shot.sh <out>.png <seconds> <flags>`. Bursts: the same with
`--press snapshot_burst <seconds>`, or, for a run no screenshot rig can carry,
`tools/run.sh <flags> --frame-record --after <seconds> --press snapshot_burst <seconds>` (a
`--route` run cannot carry `--screenshot`, and `--press` needs a screenshot or a frame-record
rig). Every run also carries `--player-view --no-save`. A sheet is the named frames of one burst,
cropped and scaled, labelled with its frame number and the frame's time in the burst; no
frame is edited. The sheets were assembled with a throwaway Pillow script kept outside the
repository.

## What each file shows

### minty-quail-4: the outcome screens (stills, head alone)

A section of the escape loses by the clock here: `--day-length 4` shortens the section to four
seconds and `--press ui_accept 1.5` dismisses the brief first, so the outcome screen carries the
timeout's reason, "Dusk. You are still out.", under the section's own words.

- `4-building-brief.png`: `--start-escape`, the building's brief ("Escape the building", the
  nerves left) over the flat's floor.
- `4-lost-building-section.png`: `--start-escape --day-length 4 --press ui_accept 1.5`.
- `4-city-brief.png`: `--start-escape city`, the city's brief over the street at the service exit.
- `4-lost-city-section.png`: `--start-escape city --day-length 4 --press ui_accept 1.5`.
- `4-hard-run-last-nerve-outcome.png`: the same city loss with `--hard --nerves 1`; the
  outcome screen reads "Nerves left: -".
- `4-hard-run-game-over.png`: the same run after a second `--press ui_accept 8`: GAME OVER.

### minty-quail-5: a cat crossing (burst, head alone)

`5-cat-crossing.png`: `--seed 4242 --day 1 --force cat_dash 2 --walk 1s20e --invincible
--press snapshot_burst 7`, eight frames cropped to the street. The cat (the small figure with a
yellow outline) comes down the sidewalk, crosses the road beside her and carries on. **What it
does not show:** the cat is cut at a solid and goes round one; this crossing meets none. The
other three pictures the record asks for (a departure round a building, the neighbor at a
barricade, a walk-back round a body) are not taken: no flag puts a solid in a mover's way, and a
recipe places events and seals by name at production sites, not a body on a mover's route. They
were read against the flags and the recipe fields, not attempted by trial.

### minty-quail-6: draw order (stills, head alone)

Every one is `--spawn event:<id> --invincible` with the seed and day named; the player stands
beside the event's nearest end.

- `6-end-on-spreads.png`: the roadworks (`construction`), the stall, the barricade, the
  scaffolding, the collapsed frontage and the roadblock's band, each standing along a north-south
  stretch (seed 11, 90210, 90210, 90210, 4242, 4242; day 12). She stands against the near end of
  each, so each piece sorts against her slice by slice.
- `6-cafe-and-protest.png`: the café's tables and sitter, and the protest's ranks (seed 4242,
  day 12).
- `6-wide-scenes.png`: the burst water main on an east-west street (seed 11) and on a
  north-south one (seed 4242), day 12; `6-wide-scene-band-joins-3x.png` is a 3x crop of the first
  where its bands meet: no seam is visible to the eye in that crop. The seed 4242 still is the
  band running across a north-south street, which the record's wording does not ask for; it is
  kept as it was taken.
- `6-escape-city-section.png`: the escape's city section on its own (`--start-escape city
  --press ui_accept 1 --invincible`), once plain and once with debug layers 1, 3 and 7: no
  building of the escape's first section is drawn over the street.

**Not taken.** The halo over the buildings in the escape's city: `--meters 100 85` raised the
excitement meter to 31 and the still shows no halo, so it is not claimed. The debug view over
the tunnel's dark and over the warning guard: `--spawn` is ignored on the escape city's boot (she
always starts at the service exit) and a `--walk north` run did not move her, so neither was
reached.

### minty-quail-7: the building (bursts, head alone)

`tools/run.sh --start-escape --route tunnel --frame-record --after 42 --invincible` with
`--press snapshot_burst` every 3 to 4 seconds; the route rig walks the building door to door.
v0.29.2's route rig does not walk the building at all (its runs sat on the building's brief or
on the flat's floor), so there is no pre-refactor burst of these.

- `7-masked-man-stairwell.png`: frames 24 to 36 of one burst in the stairwell. The edge badge
  stands over the masked man (the circle with an arrow and a distance) before he is in view; he
  comes up the lower flight and is in view, outlined, at frames 35 and 36. The record's "leaving
  round the walls at the top of the shaft" is not in this burst.
- `7-basement-mouse-dash.png`: frames 14 to 24 of one burst in the basement. The mouse comes out of
  a grate beside her at frame 18 and crosses the passage in frames 19 to 24; the distance wall to
  wall (the record's 27 px) is not measured by a picture.
- Not taken: the mark over her head in the stairwell. The marks beside her head in the
  stairwell frames are the baby's sleep marks (the "zzz"), and no frame is read as the "soon"
  cue's mark; the run log lines are in `raw/masked-and-mouse-run.log-lines.txt`.

### minty-quail-15: the badges (bursts, head and v0.29.2)

`15-charging-dog-badge-head-and-v0.29.2.png`: `--seed 4242 --day 5 --force charging_dog 3 --walk
1s30e --invincible --press snapshot_burst 4 --press snapshot_burst 8`, the first burst's frames
1, 8, 15 and 22 on each tree. The two trees place different things round her (placement moved on
purpose), so the surroundings differ; the dog comes down the road in both and both show a badge
over his arrival. What the run log adds, in `raw/dog-head-badge-lines.txt` and
`raw/dog-v0.29.2-badge-lines.txt`: head raises each charger's badge with `closing 130px/s` (his
own speed, from the frame he runs); v0.29.2 raises the same badges with `closing 0px/s`, and in
one cycle drops the badge before the chase line where head drops it after. The still cannot show
the timing, only the badge's presence. **Not taken:** overlapping badges. `tools/shot.sh` cannot put
several dangers off one edge with its flags or a recipe (`--force` hands out one row; a recipe
cannot site a second charging dog or fire engines at chosen tiles), so the still needs a harness
that does not exist. Building one is new code, an entry of its own if wanted.

### minty-quail-9, -21 and -26: not taken

- **-9** (a taper stepping into the park's edge row; an escort walking up beside the street
  musician): the step's own pictures are in `docs/evidence/minty-quail-cordon-busker-2026-10-31/`.
  On head, `scene-recipes/task-12-swing.json` stops at 13.3 s, 0.7 s after the swing and before
  the cordon is far along, and `--press` conflicts with a recipe so no burst can be asked for.
  Three scratch copies with longer `playback` times (stopping at 15, 19 and 24 s) wrote no picture,
  the 15 s one ending on the scene's own "gameplay paused before the authored action completed". No busker
  stands in the scene.
- **-21** (the walking bob stepping every other drawn frame at 60 fps): the capture window draws at
  140 to 570 frames a second here (the run logs' frame lines), not at 60, and a burst's frames are
  about 83 ms apart, so a burst cannot show stepping between drawn frames. Not claimed.
- **-26** (an arrow field's sweep at 60 fps; the cordon officers' stride at 30 Hz): the same
  spacing applies, and the cordon is not reached (above). Not taken.

### minty-quail-8: the escape city's home door (not taken)

The door shows its sealed picture once day 10's raid has left the `sealed_door` scar in the run
(`src/city/city.gd`'s `SEALED_DOOR_SCAR`). No dev flag or recipe field sets that scar and a
boot from `--start-escape` has none; reaching it needs a played day 10. Not staged.

### minty-quail-calm-marmot: the ground a deadly event shuts (still, head alone)

`marmot-roadblock-debug-layers.png`: `--seed 4242 --day 13 --spawn event:roadblock --layers 1,3
--invincible`. Layer 1 draws every field's outline (the lethal ones in deep red, the costly in
amber) and layer 3 the bounding boxes. **It does not draw the plan's blocking disc**
(`EventPlan.blocking_radius()`), which has no debug layer: the pictures that show it are the
probe's, in `docs/evidence/minty-quail-blocking-reach-2026-11-23/`. This one shows the roadblock's
band and the fields round it on head, for beside those.

### minty-quail-3: a recorded recipe's log (logs, never the video)

`tools/record.sh --out mq-r4-<tree>.mp4 -- --recipe scene-recipes/task-06-note.json` on each
tree, one after the other (day 6, seed 11, 13.3 s). The video, the frame hashes and the audio are
not kept; `raw/l6-*` holds the run log of each tree, their diff, each recording's manifest and
the recording settings.

- **Picture filenames:** both trees wrote `auto/001-attempt1-chase-robber_giving_chase.png`, one
  picture each, the same name; the attempt suffix is present on both.
- **The day header:** head's log opens `day 6  act 2  run seed 11  city seed 1917501  length
  180.0s`; v0.29.2's has no header (the recorded expected difference).
- **Timestamps:** head's lines carry the run's times (0.6, 1.0, 1.3 s ...); every line of v0.29.2's
  carries 0.0.
- **Lines:** with the texture and frame lines left out, v0.29.2's log has 33 lines and head's 36.
  Head adds the header and a `run` line ("ran 1.7s ... nearest when it started: alley_robbery
  266px"); the `cue` lines' "soon for" times differ (head 0.9 and 0.4 s, v0.29.2 0.0 and 0.0 s);
  the `near` lines' distances and meter figures differ (a cat 147 px and 79 px away on head
  against 117 and 62 on v0.29.2); and the edge-badge line for the robber's chase reads `closing
  130px/s` on head against `0px/s` on v0.29.2 (the minty-quail-15 change).
  `raw/l6-diff-v0.29.2-to-head.txt` is the whole diff.
- **Frames:** every one of the 720 frames of the two recordings has a different hash.

### Behaviors with no picture to take

minty-quail-10, -13, -14, -20 and -23 changed behaviors the records read off the code or hold
with a suite. They are listed so the set is complete: a notice carried across a stream-out keeps
its held time (-10, `test_event_phase`'s round trip on the alley robber) and a streamed-out event
comes back with every behavior's state (-13, `test_event_behaviours`' round trips), neither
measured in a played day; the run's state kept in one list (-14, read off the code, no suite
named); a continue with no screen up leads nowhere (-20, `test_run_flow`); play time counts the
ticks that ran (-23, `test_main`'s five-second drawn frame adding none, and `test_save`).

## Not picturable here

The phone's draw buckets (minty-quail-silky-penguin, -silky-stork) need a published build's phone
frame record, which merry-lynx already asks the player for. The web page's frame-record save
button in a real browser (minty-quail-fluffy-lark) and a held restart while a flush is pending
on a web export (minty-quail-striped-quail) are a person's checks on the published page: the
review item `docs/review/minty-quail-*.md` of this pull request asks for them.

## Retained, and what is left out

16 pictures (7 stills, 8 sheets and 1 crop) and 15 files under `raw/`: five `burst-*.json`
frame-time files, four files of the run-log lines each claim rests on, the two recording logs and
manifests of the recipe comparison, its diff and the recording settings. Every picture but the
six outcome stills is a 256-colour PNG. Left
out in scratch space: every other still and burst of the trial runs (a failed or
off-target capture is listed above with its reason), the recordings, their frame hashes, and
the full run logs of the bursts.
