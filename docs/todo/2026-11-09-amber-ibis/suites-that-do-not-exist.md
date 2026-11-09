# No doc or comment names a suite that does not exist

`tests/test_events.gd` and `tests/test_routes.gd` do not exist. The skills no longer cite them;
about a dozen doc sentences and about forty code comments still do: `docs/EVENTS.md` (nine places,
among them the sentence that a suite "asserts it across a whole run" for the lethal field, and
step 5 of "Adding a new event"), `docs/MECHANICS.md`, `docs/CITY.md`, and comments in
`src/autoload/tuning.gd`, `src/events/event_catalogue.gd`, `event_def.gd`, `event_scheduler.gd`,
`src/field.gd`, `src/player/baby.gd`, `stroller.gd`, `src/routes/closure_planner.gd` and
`src/city/city_generator.gd`.

**Build:** each sentence names the suite that holds the check it speaks of
(`tests/test_events_catalogue.gd`, `test_events_solid.gd`, `test_events_costs.gd`,
`test_tuning_fairness.gd`, the closure rigs and the lattice suite), or says the rule is unenforced
where nothing holds it. A lint that fails a doc or a comment naming a `tests/` file that does not
exist keeps it from coming back.
