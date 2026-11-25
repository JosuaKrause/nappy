# The run's rows, built once in main and handed to what reads them

`main.configure()` builds the run's rows once from the run's `ChargerTiming` and hands that object
to everything that reads a row: the event manager, the scheduler and its sitings, the resistance
director and the rest of the static catalogue's callers. Every caller of `EventCatalogue.by_id()`,
`heated()`, `mark_guard()`, `task_guard()`, `out_of_the_car()` and the other row accessors
moves to the handed object, so a test hands it a timing or a fake. The static `EventCatalogue`
then keeps only what depends on nothing a run sets, or goes. `EventCatalogue._chargers` and
`use_charger_timing()` are deleted, together with their exception in `tools/layer_map.py` and its
declaration in **designing-classes**, "Code is designed by layer".

Its size when filed: 47 files under `src/` (128 calls into the catalogue) and 183 files under
`tests/` and `tools/` (991 calls), since every row reaches its readers through the static
catalogue (under `src/`, `by_id()` 46 times and `heated()` 11). `tools/check_layers.py` reports
ten files under the exception: the readers in the world and simulation layers. The rest read the
catalogue from layers the static rule does not police.
