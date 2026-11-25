# striped-marten — Day one's five milestones are counted in GoatCounter · 2026-11-25

striped-marten's `day-one-milestones.md`, in #1201: GoatCounter events for day 1's milestones, so
`tools/goatcounter.sh` shows where a new player stops (curly-moose #819), shipped as a patch ahead of
grassy-beaver (a day one that teaches) so a window before the change exists to compare against.

**Built.**
- **`nappy-day-1-first-crossing`**, on her first step onto a road or crossing tile, from a new
  `EventBus.road_entered` signal; **`nappy-day-1-park-reached`**, on her first step onto calm
  ground, from a new `EventBus.calm_ground_entered`. `DayController.tick()` emits both, since it
  holds the home map, the player and every tick; it re-reads what she stands on at `start()`, so dawn
  on a road or calm tile is not an arrival. A walk with no home map (the escape) says nothing.
- **`nappy-day-1-asleep`**, from the existing `EventBus.return_phase_started`.
- **`nappy-day-1-first-obstacle`**, from a new `EventBus.encounter_passed(day, name)`, which
  `EncounterWatch` emits when an encounter it had seen is over while the day goes on (the instance
  out of sight for `ENCOUNTER_GAP`, or gone); `EncounterWatch.end_day()` closing one is not a pass.
- **Home** is the existing `nappy-day-1-won`, not a second event.
- **Once per attempt, day 1 only:** `VisitCounter` clears its milestone set on every walk's
  `day_started` (a fresh day 1, a retry after a loss, a return to checkpoint day 1) and counts only
  on day 1, so the escape's sections, which count under their own numbers, send none.
- `tools/goatcounter.sh` groups any `nappy-day-N-*` name in its funnel, so it shows the new events
  unchanged; `docs/TELEMETRY.md` lists them.

**Choices where the design was silent, open to overturn:** "park reached" fires for any calm
ground (park, forest, square, courtyard, alley), since day 1's calm may be any of them; "first
crossing" is the step onto the road, as the run log's `cross` line counts it, not reaching the far
curb. "Obstacle passed" is **a seen event left behind**, every catalogue row alike, because the
events know no sharper test: a static row (a fallen tree, roadworks) is never influenced, and a
pass can also be her turning back. **Once grassy-beaver makes crossing a day-one lesson, "first
crossing" means something different than today's step onto a road**, so a read after that change
is not comparable with the one before it on that event alone.
