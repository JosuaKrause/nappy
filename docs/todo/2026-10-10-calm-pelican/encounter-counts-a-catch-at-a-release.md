# A catch on the frame a door releases her counts as influenced

**Low · from the re-review of PR #589 (Influenced counts a real catch or hold).** In
`EventManager._tick_the_events`, the encounter watch runs before `_check_detentions()` and
`_check_hard_fails()`, so when a hut inspection sets her down within reach of a cyclist past its
warning, the day ends at her new spot and the summary pauses the game before the watch sees the
catch; GoatCounter's `influenced` is never sent, against #577's "let's count chases and catches as
influenced always". Let `_check_hard_fails()` tell the watch which instance struck her (for example
`EncounterWatch.caught_by(instance)`), or add a catch-only check after `_check_detentions()`; test a
release into reach. And `docs/TELEMETRY.md` and `src/events/encounter_watch.gd` say "a pursuer
chases from the first frame after its telegraph", false for a waiting pursuer, who chases only once
she is within `pursues_within`: say "from the moment it comes for her (`EventBus.pursuit_began`),
which is before she is within its reach".
