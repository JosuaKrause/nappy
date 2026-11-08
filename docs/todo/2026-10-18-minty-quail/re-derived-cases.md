# The other facts derived in more than one place

**The ask.** "try finding more such cases -- that's a code smell" (inbox #1156 in gray-dolphin). On the board's
re-derived-state-cases, "yes" to the order picked: what blocks the way and the door flag in the live
form after dawn; two cases with the dawn plan object; three cases one small pull request each; one
case once the plan object exists (inbox #1156 in gray-dolphin).

**Read as:** one fact derived from raw data in more than one place, or a private method re-deriving
what another place already worked out, is moved into one object that derives it once and is handed
to whoever asks (designing-classes). The dawn cases were built with `DayEvents`, `CalmAreas` and
`DayRepairs` (#1158); the after-dawn ones with `WalkEvents` and `DayReach` (#1169).

**What is left: two cases, as the orchestrator's notes name them.** The survey that described the
cases is gone, and the board's numbering of them (3, 4, 6 and 7 among them) was not kept with the
names, so which number each is cannot be told from what is on disk. Each case is found again, with
its places in the code, before it is designed. Where to look first:

- **The held streets' reasons:** which street segments are held and why, which `CityMap.is_held()`
  and `is_held_at()` answer and `CrowdPockets._shut_the_held_segments()` and
  `ResistanceSteps.stands_on_held_ground()` read again for themselves.
- **The ground cache:** which tiles each row may stand on (`EventScheduler.open_ground_for()`), a
  per-day cache `build_day()` builds at dawn and each `WalkSiting` builds again for itself.
