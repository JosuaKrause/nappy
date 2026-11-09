# striped-marten — Four of day one's milestones are counted in GoatCounter · 2026-11-07

striped-marten's `day-one-milestones.md`, in #1201: GoatCounter events for day 1's milestones, so
`tools/goatcounter.sh` shows where a new player stops (curly-moose #819), shipped ahead of
grassy-beaver so a window before the change exists to compare against.

**Built.**
- **`nappy-day-1-first-crossing`**, on her first step onto a road or crossing tile, from a new
  `EventBus.road_entered` signal; **`nappy-day-1-park-reached`**, on her first step onto calm
  ground, from a new `EventBus.calm_ground_entered`. `DayController.tick()` emits both, since it
  holds the map, the player and every tick; it re-reads what she stands on at `start()`, so dawn on
  a road or calm tile is not an arrival.
- **`nappy-day-1-asleep`**, from the existing `EventBus.return_phase_started`.
- **Home** is the existing `nappy-day-1-won`, not a second event.
- **Once per attempt, day 1 only:** `VisitCounter` clears its milestone set on every `day_started`
  (a fresh day 1, a retry after a loss, a return to checkpoint day 1) and counts only on day 1.
- `tools/goatcounter.sh` groups any `nappy-day-N-*` name in its funnel, so it shows the new events
  unchanged; `docs/TELEMETRY.md` lists them.

**Choices where the design was silent, open to overturn:** "park reached" fires for any calm
ground (park, forest, square, courtyard, alley), since day 1's calm may be any of them; "first
crossing" is the step onto the road, as the run log's `cross` line counts it, not reaching the far
curb.

**Left:** first obstacle passed, which needs a signal from the events (the item's file says how).
