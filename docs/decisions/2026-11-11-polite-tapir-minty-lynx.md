# polite-tapir — The events' model files move to src/events/model · 2026-11-23

**What was asked.** polite-tapir's `standing-layer-breaks.md` asks that `src/events/` stop taking the most
permissive layer by default for a new file, and the player's pick on the board question of where an event's
settings files live was the full split of the events folder by layer once placement closes (inbox #1278 in
olive-ferret, statements 1 and 2). This is the second of the three moves, the model layer.

**What was built.** The 36 files at `src/events/` that the map gives the model layer, `dawn_phases/` and
`street_rules/` whole moved to `src/events/model/`, with their `.uid` sidecars, by `git mv`: 120 renames at
100%, no file's contents touched and no file or class renamed. The 36 per-file lines, the 9 of the street rules and
the `dawn_phases` folder line of the map became one folder line, `"src/events/model": "model"`. The rules hook,
`CLAUDE.md`'s table and `tools/test_rules_hooks.sh` name the scheduler, the two ruled grounds, the dawn's masts and
spoilers and the unit fills (all **balance**) at the new paths, `tests/test_texts_catalogue.gd` the dawn phases'
folder and the scheduler, and `tools/field_reads.txt` and `tools/test_only_members.txt` carry the new paths. The
docs that name the paths follow, and `docs/ARCHITECTURE.md` groups the model files under a `model/` heading. The
layer of every class is what it was. The `src/events` simulation default stays until the third pull request.

**The item.** The split stays open for the simulation move.
