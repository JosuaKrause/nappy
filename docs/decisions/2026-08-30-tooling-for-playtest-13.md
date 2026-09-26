## Tooling for playtest 13 · `feature/a-picture-of-the-city`

Findings 4 and 5. Small, asked for by name, and **built first**, because M46 and M47 both want
exactly what they provide. Neither is a game feature; both go with the dev flags and under the
same eventual debug-build gate.

- [x] **Render the whole city grid to a picture in the telemetry folder** — finding 4. Not
      `--overview`, which is a dev flag on a run somebody has to take and which photographs the
      *rendered* city: this is the grid itself, one small square per tile coloured by tile type,
      written beside the log every run without anybody doing anything. Everything needed exists —
      `Tile` decides the colour, `CityMap` holds the grid, `Telemetry` owns the directory and the
      naming. Mark what a trace cannot say in words: the home, the calm areas, the main road, the
      precincts, the day's closures. It must obey the telemetry invariant — **no RNG, nothing that
      changes a placement** — and it must cost nothing when telemetry is off
- [x] **A key that takes a screenshot and writes a note** — finding 5. `Telemetry.snapshot()`
      exists and is heuristic; what is missing is the player saying *look at this*. Its own key, it
      **bypasses `SHOTS_PER_DAY`** (a person asking is not a heuristic firing), and it writes a
      `note` alongside so the picture has a line in the trace to sit next to — position, day,
      meters, and what is near her. Note the M36/M38 lesson before wiring it: nothing in the suite
      or a screenshot has ever pressed a key, and a bare key is not an action — `--press key:<x>`
      is how it gets tested at all

**Both built, and it is `TelemetryMap` plus twelve lines in `main.gd`.** `P` (or `F9`, two
bindings because a bare F-key is the convention and is also what macOS hands to the volume control
unless a setting is changed) writes `<stem>-<clock>s-asked.png` and a `shot` entry; every day
writes `<stem>-map-day<NN>.png`, 640px square and about 5kB.

**Three things were found by building it, and two of them are the reason it has tests.**

- **A float colour does not survive `FORMAT_RGB8`.** The marks were authored as
  `Color(1.0, 0.25, 0.35)` and read back a fraction off, so the test that asked *is this mark in
  the picture* failed against the constant it had just drawn with. They are hex now, like
  everything in `Palette`, and the ground colours never had the problem because `Palette` already
  was.
- **`snapshot_now` guarded the note and the picture together, and the suite is the configuration
  that keeps the note.** `begin_memory_log()` produces a log with no path, which is a real state
  rather than an edge case, and one guard covering both halves made the entry vanish along with
  the PNG it could not write. They are guarded separately.
- **The home crosshair was built and taken back out.** It reached a block either way to make a
  few tiles of stoop findable in a 160-tile map — and it is the only red in a picture with no
  other red in it, so it was already the first thing the eye lands on. It was covering two streets
  to buy nothing. *(Reported directly: "the home cross hair is not needed — home was easily
  findable with just the red dot from before.")*

And the first two maps it drew already show M47's own finding without anybody measuring anything:
calm areas hard against the map edge, and one directly beside the spine.
