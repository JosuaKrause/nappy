# main.gd split into an explicit run flow

**Carry-over for the events PR 4** (the events agent's files): these read the run off `GameState`
rather than being handed it — `src/events/event_manager.gd`, `event_scheduler.gd`, `event_def.gd`,
`event_catalogue.gd`, `event_director.gd`, and `src/resistance/resistance_director.gd`,
`happenings.gd`, `resistance_steps.gd`.
