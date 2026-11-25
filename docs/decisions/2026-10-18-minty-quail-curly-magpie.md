# minty-quail — The end remeasure's pictures · 2026-11-24

**What it is.** Group P of minty-quail's end remeasure (the entry's README, step 3): pictures
of what the refactor's steps changed on purpose, taken windowed on head and, where the same flags
stage the old behavior, beside v0.29.2. The pictures, the commands, every flag and seed and
what each cannot show are in `docs/evidence/minty-quail-end-pictures-2026-11-24/`. Head is
`47e4654388004cb1ee9bc0f52a676f4d8b2e0013` (its last code change is
`f98443b5b19ddada1899c13c4d939d84049ea453`); the pre-refactor tree is the tag v0.29.2
(`094536ab0a34842aa4dfd523dde2191d8c6814e5`), the release that keeps downy-tapir's escape
changes out of the comparison. Nothing under `src/`, `tests/` or `tools/` changed, and nothing
is judged: a picture is listed with what it shows and what it cannot.

**Taken** (16 pictures, 3.5 MB with the raw files).

- **The outcome screens** (minty-quail-4, head alone): the escape's two briefs, a lost building
  section and a lost city section with the reason the clock gives ("Dusk. You are still out.")
  under the section's own words, a hard run's last nerve ("Nerves left: -") and the GAME OVER
  after it. A section loses here by the clock (`--day-length 4`), not by a catch.
- **A cat crossing** (minty-quail-5, head alone, burst): the cat comes down one sidewalk, crosses
  the road beside her and goes on. It meets no solid, so the cut-at-a-solid case the record is
  about is not in it.
- **Draw order** (minty-quail-6, head alone, stills): six spreads standing along a north-south
  stretch with her at their near end (roadworks, stall, barricade, scaffolding, collapsed
  frontage, roadblock band), the café's tables and sitter, the protest's ranks, the burst water
  main on an east-west and on a north-south street with a 3x crop of its band joins (no seam
  visible to the eye), and the escape's city section with none of the building drawn.
- **The building** (minty-quail-7, head alone, bursts through the route rig): the edge badge over
  the masked man and then the man himself coming up the stairwell's lower flight, and the
  basement mouse crossing its passage. v0.29.2's route rig does not walk the building, so there
  is no old burst.
- **The badges** (minty-quail-15, head and v0.29.2, burst): a charging dog's badge over his
  arrival on both trees; the run logs carry the difference the stills cannot, the badge raised
  with `closing 130px/s` on head against `0px/s` on v0.29.2 (minty-quail-velvet-yak's change, PR
  #1478: a pending warning's badge is listed at the row's approach speed).
- **A roadblock with the debug layers** (minty-quail-calm-marmot, head alone, still): the fields
  and bounding boxes round one. Neither layer draws the plan's blocking disc, whose pictures are
  the probe's in `docs/evidence/minty-quail-blocking-reach-2026-11-23/`.
- **A recorded recipe's log** (minty-quail-3, head and v0.29.2 through `tools/record.sh`; the
  video kept nowhere): the same picture filename on both (the attempt suffix is on both), the
  day header only on head, head's lines timed where every line of v0.29.2's carries 0.0 (the
  recorded expected difference of minty-quail-3: a recipe day now has a header and the day's clock), the same
  kinds of line in the same order apart from head's added `run` line, and a different hash for
  every frame.

**Not taken, with the reason.** Overlapping badges (minty-quail-15): a recipe's `setup.events` takes
several pinned rows with a `charging` flag; what stops a second charging dog off one edge is ordinary
placement (`EventScheduler.recipe_placement()`) and the per-day cap, read and not tried. A departure round a building, the neighbor at a barricade and a
walk-back round a body (minty-quail-5): no flag puts a solid in a mover's way and a recipe places events
at production sites, not a body on a mover's route; read against the flags, not tried. The halo over the buildings and
the debug view over the tunnel's dark and the warning guard in the escape's city (minty-quail-6):
a raised meter showed no halo, and `--spawn` is ignored on the escape city's boot. A taper
stepping into the park's edge row and an escort beside the busker (minty-quail-9): the swing
recipe ends 0.7 s after the swing and conflicts with `--press`, and three longer scratch copies
wrote no picture; the step's own pictures stand in
`docs/evidence/minty-quail-cordon-busker-2026-10-31/`. The walking bob at 60 fps (minty-quail-21)
and the arrow field's sweep and the cordon officers' stride (minty-quail-26): the window draws at
140 to 570 frames a second here and a burst's frames are about 83 ms apart, so no burst can show
stepping between drawn frames; `tools/record.sh` writes 60 frames a second but turns physics
interpolation off, so it shows the tick and not the interpolated drawing, and was not tried. The escape city's sealed home door (minty-quail-8): the sealed
picture needs day 10's raid to have left its scar, which no flag sets. The epilogue
(minty-quail-4): the route rig ends the run as she arrives and no flag walks her to the exit
with a screenshot rig; the route rig quits at any day ending, and three runs, bursts timed to its end,
caught no epilogue.

**Behaviors with no picture to take.** minty-quail-10, -13, -14, -20 and -23 changed behaviors
the records read off the code or hold with a suite (a notice and a streamed-out event's state
across a stream-out, `test_event_phase` and `test_event_behaviours`; the run's state in one list,
read off the code; a continue with no screen up, `test_run_flow`; play time counted in ticks,
`test_main` and `test_save`). The evidence README lists the suite each one is held by.

**Not picturable here.** The phone's draw buckets (minty-quail-silky-penguin and -silky-stork)
need a published build's phone frame record, which merry-lynx already asks the player for. The
web page's frame-record save button and a held restart with a flush pending on a web export
(minty-quail-fluffy-lark and -striped-quail) are a person's checks on the published page, and
`docs/review/` holds their review item.

**Seen once, not reproduced at head.** While the pictures were taken, `--seed 4242 --start-escape
--route tunnel --frame-record --after 38` once booted on "Day 1 of 14" and a day-1 brief for the
whole run, and two later route runs seemed to sit on that brief after the exit. The review reran
that command three times at this head (twice headless, once windowed) and every run opened the
building and walked out of it: `--seed` only reaches the run's start, which world opens is
`--start-escape`'s alone, and the route rig quits at any day ending so it cannot sit on a brief.
A run on another tree (the v0.29.2 worktree) or a command that lost `--start-escape` would
explain the sighting. No entry is filed.

**Defects.** Two, both reported to the orchestrator and filed as `bug` entries, neither fixed here.
The screen-edge badge's closing speed grows with the frame rate (the entry "The screen-edge badge's
closing speed grows with the frame rate"): the masked man's badge logs `closing 1949px/s` in
`raw/masked-and-mouse-run.log-lines.txt` against about 110 documented, because the badge measures
every drawn frame while positions move only on the 30 Hz tick and the first-moving-frame rule keeps
the spike. And a catch by the escape city's roadblock shows the fallback loss text "It went wrong."
(the entry "A roadblock catch in the escape city shows the fallback loss text"), which v0.29.2
shows too.

**Owed.** The pictures not taken are an entry of their own, "The pictures the end remeasure could
not stage", with what would stage each.

**Footprint.** The evidence folder holds one README, 16 pictures and 15 files under `raw/`: 32
files, 3.5 MB.
