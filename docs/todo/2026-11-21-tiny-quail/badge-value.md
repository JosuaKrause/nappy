# A screen-edge danger badge is a typed value, not a dictionary

**What is wrong today.**

- `EdgeBadges.announcing()` (`src/ui/edge_badges.gd`) answers `Array[Dictionary]`, "each carrying
  at least `id`, `distance` and `approach`". The run log reads `badge["id"]`, `badge["distance"]`
  and `badge["approach"]` (`TelemetryObserver._watch_the_cues()`). A dictionary key is a field in
  everything but name, and less checked than one: the engine's typed-access errors and
  `tools/check_field_reads.py` see neither a key nor a misspelt one, and the stand-in the
  observer's suite hands in (`StandInBadges` in `tests/test_telemetry_observer.gd`) copies the
  shape by hand. Fields are not API (inbox #1173 in gray-dolphin), code is typed wherever the
  language can type it (inbox #1280 in olive-ferret), and a test reads its subject through methods
  (inbox #1182 in gray-dolphin); a dozen suite lines read `badge["id"]`.
- **One list serves two readers with different needs.** `BadgeModel.announcing()` adds `def` (the
  row) and `position` (where the badge points) for the edge's drawing, so the run log is handed the
  row and the drawing is handed the log's name. Each reader holds what it would not miss.
- **The model keeps the same badges twice.** `BadgeModel.coming` is a public, untyped array of
  positional rows (`[time_to_reach, distance, payload, world position, approach, logged name]`),
  and `announcing()` builds a fresh list of dictionaries from it on every call, twice a frame while
  a badge is up (the edge's draw and the run log).

**The design.**

- `EdgeBadges.Badge`, an inner class of `src/ui/edge_badges.gd` (the file stays on the model layer
  and still names nothing): a `RefCounted` built with its three values, kept in underscore fields,
  answering `logged_name() -> String` (today's `id`, the name the log calls the thing by),
  `distance() -> float` (px from her) and `approach() -> float` (px/s it closes at under its own
  steam). `EdgeBadges.announcing() -> Array[EdgeBadges.Badge]`; the base still answers none.
- `BadgeModel.Drawn extends EdgeBadges.Badge`, an inner class of `src/ui/badge_model.gd` (view):
  the same badge as the edge draws it, adding what only the model's sort and the drawing read:
  `arrives_in() -> float`, `row() -> EventDef` and `points_at() -> Vector2`. `BadgeModel.Subject`'s
  `payload` is typed `EventDef` with it: every caller that sets it hands a row
  (`DangerEdge.subject_for_def()`, and `tests/test_observers.gd`), and a suite that sets none keeps
  null.
- `BadgeModel` keeps one list, `_coming: Array[Drawn]`, built once in `step()` and sorted by
  `arrives_in()`; the public `coming` goes. `announcing()` answers those same objects as
  `Array[EdgeBadges.Badge]` (the override's signature is the base's); a second method,
  `drawn() -> Array[Drawn]`, answers them for `DangerEdge._draw()`. `has_badges()` and
  `clear_badges()` stay.
- Readers: `TelemetryObserver._watch_the_cues()` asks the three methods; `DangerEdge._draw()` reads
  `_model.drawn()`; the suites, the rig `tests/masked_man_meeting.gd` and the probes that read
  `badge["id"]` and the like ask the methods; `StandInBadges` holds `EdgeBadges.Badge` objects.

**Order, one pull request:** the value and the base's signature; `BadgeModel`; the two readers
under `src/`; the suites and probes. Its description shows
`rg -n '\["(id|distance|approach|def|position)"\]' src tests tools` and
`rg -n '\.coming\b' src tests tools`, every remaining hit with its reason (the model's own
per-subject state dictionary `_watch` keeps an `"approach"` key inside its file; it goes with
tawny-wombat's deletion and is not this change's).

**What holds parity.** Nothing a player sees changes, and the run log's lines are byte for byte the
same: `tests/test_telemetry_observer.gd`'s case pins both lines and `tests/test_observers.gd`
holds the real boot's hand-off; the same short headless day #1567 compared (`--no-save --no-title
--seed 4242 --day 6 --day-length 30 --force fire_truck 4 --walk 12n10e`, read back with
`./tools/telemetry.sh`) matches line for line on base and branch, frame lines left out. The badges
are drawn in the same order from the same values (`tests/test_danger_edge.gd`,
`tests/test_badge_model.gd`).

**Cost.** Small. Four files under `src/` (`edge_badges.gd`, `badge_model.gd`, `danger_edge.gd`,
`src/telemetry/telemetry_observer.gd`) and about ten suites, rigs and probes with one to five
lines each. Per frame it allocates less: the badges are built once a step, with no dictionaries per
call. The layer map does not change.

**What it collides with.**

- **minty-quail's `event-interface.md`, row 4b (a row is written as its parts):** its pull requests
  rewrote suites that build rows, several of them suites this change edits a line of
  (`test_danger`, `test_events_pursuit`, `test_interior`). What is left of row 4b (the composer's
  writes of the live event's behaviour slots, two unused members) touches none of them, so it can
  start.
- **Row 5 of the same file (the events' suites test one module each):** land **before** its group
  that moves `test_danger`'s events-and-badge half, so the moved tests and their stand-ins are
  written once against the final interface.
- tawny-wombat (the army truck and the stairwell masked man are placed after their badge, after the
  refactor) and misty-raven (the danger cues and the events do less work; its item skips events in
  `DangerEdge`'s measuring) touch the model's and the edge's measuring, not these lines: either
  order. gentle-finch (the edge badge's pointer becomes a picture file) touches `_draw_chevron()`
  only.
