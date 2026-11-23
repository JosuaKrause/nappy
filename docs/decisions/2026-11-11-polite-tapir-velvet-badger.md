# polite-tapir — The data files move to src/events/data · 2026-11-23

**What was asked.** polite-tapir's `standing-layer-breaks.md` asks that `src/events/` stop taking the most
permissive layer by default for a new file. The player's pick on the board question of where an event's settings
files live was a folder `src/events/parts/` now and the full split of the events folder by layer once placement
closes (inbox #1278 in olive-ferret, statements 1 and 2). Placement is closed, so the split is built, in three
pull requests; this is the first, the data layer.

**What was built.** The seven data files at `src/events/` (`event_catalogue`, `event_def`, `event_draft`,
`event_scenery_parts`, `placement_density`, `placement_ground`, `placement_view`) and `parts/` whole moved to
`src/events/data/`, with their `.uid` sidecars, by `git mv`: 50 renames at 100%, no file's contents touched and
no file or class renamed. The map's 25 per-file lines for them became one folder line, `"src/events/data": "data"`.
`tools/test_only_members.txt` carries the new paths, `tools/split-scenes.py` writes `event_scenery_parts.gd` at its
new path, and the rules hook, `CLAUDE.md`'s table and `tools/test_rules_hooks.sh` name the catalogue and the
density table (both **balance**) at the new paths, the density table gaining a case of its own in the hook's test.
The docs and skills that name the paths follow, and `docs/ARCHITECTURE.md` groups the events listing's data files
under a `data/` heading. The layer of every class is what it was. The `src/events` simulation default stays until
the third pull request.

**The item.** The split stays open for the model and simulation moves.
