# polite-tapir — The simulation files move to src/events/simulation and the folder default goes · 2026-11-23

**What was asked.** polite-tapir's `standing-layer-breaks.md` asks that `src/events/` stop taking the most
permissive layer by default for a new file. The player's pick on the board question of where an event's settings
files live was a folder `src/events/parts/` now and the full split of the events folder by layer once placement
closes (inbox #1278 in olive-ferret, statements 1 and 2). This is the third and last of the three moves, the
simulation layer.

**What was built.** The 26 simulation files left directly in `src/events/` (`charge_record` to `where_she_is`),
`behaviours/` and `views/` whole moved to `src/events/simulation/`, with their `.uid` sidecars, by `git mv`:
no file or class renamed and no layer changed; the only contents touched are four comments that named a folder
(`event_instance.gd` twice, `views/event_look.gd`, `views/event_pictures.gd`). The map holds `"src/events/simulation":
"simulation"` and the `"src/events": "simulation"` default is deleted, so a file put directly in `src/events/`, or in
a folder beside the three, is in no layer and `check_layers.py` fails it. Writing a new events file means choosing
one of `data/`, `model/` and `simulation/`, the layer's own name. The rules hook's **cues** row, `CLAUDE.md`'s table
and `tools/test_rules_hooks.sh` name the base look and the warning board at the new paths; the paths in
`tests/`, `tools/`, the docs and the skills follow, and `docs/ARCHITECTURE.md` groups the simulation files under
a `simulation/` heading.

**Five files that name nothing of the simulation stay in it**: `sited_ground.gd` (names up to the model),
`event_scenery.gd` (up to the world), `warning.gd`, `where_she_is.gd` and `views/event_pictures.gd` (data only).
Whether one belongs lower is a question about that class, and with the folders being the layers, answering it is
one `git mv` that the check then holds.

**The item.** The events folder's bullet in `standing-layer-breaks.md` is settled and deleted.
