# The park beats probe leaves a city and a bus connection behind

`tests/probes/m128_park_beats.gd` prints what the playground and the street musician (`busker`)
cost on real generated parks: how long standing at the musician's core takes to fill a sleep meter,
his denial radius, and which side of the street his field reaches.

**Its first failure:** its first measurement (`_busker_never_fills_the_day()`) builds a real `City`,
adds it under the runner and never frees it, so the city and its event manager's connection to
`EventBus.return_phase_started` (made in `EventManager.setup()`) are still there when the probe ends,
and the runner fails it for leaving shared state changed (`tests/shared_state.gd`; the record
2026-10-18-minty-quail-snowy-magpie).

*Proposed, not asked for:* fixed, by freeing the city at the end of that measurement, as the probe
already frees its stroller and its event. Deleting it loses the one probe of the musician's reach on
real parks, whose numbers M128's record holds (the
playground is free and the busker denies sleep outright, `tools/decisions.sh M128`).
