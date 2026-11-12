# The other facts derived in more than one place

**The ask.** "try finding more such cases -- that's a code smell" (inbox #1156 in gray-dolphin). On the board's
re-derived-state-cases, "yes" to the order picked: what blocks the way and the door flag in the live
form after dawn; two cases with the dawn plan object; three cases one small pull request each; one
case once the plan object exists (inbox #1156 in gray-dolphin).

**Read as:** one fact derived from raw data in more than one place, or a private method re-deriving
what another place already worked out, is moved into one object that derives it once and is handed
to whoever asks (designing-classes). The dawn cases were built with `DayEvents` and `CalmAreas`
(#1158); the after-dawn ones with `WalkEvents` and `DayReach` (#1169).

**What is left: one case, as the orchestrator's notes name it,** found again with its places in the
code before it is designed; placement by construction (polite-tapir's `placement-by-construction.md`) replaces the
code it sits in, so it is done there or after:

- **The ground cache:** which tiles each row may stand on (`EventScheduler.open_ground_for()`), a
  per-day cache `build_day()` builds at dawn and each `WalkSiting` builds again for itself.
