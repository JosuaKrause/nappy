## M171, the ground's recipe is read once — built 2026-09-20

[PLAYTEST-111](../playtests/PLAYTEST-111.md). `GroundLayers._load_manifest()` opened the recipe
with `FileAccess` inside every `build_tile_set()`, so every day's repaint went to the disk. The
player's checkout was fast-forwarded to #257 — which moves that file — while their game ran;
day 2 found no recipe, composed nothing and drew the whole authored tiles, with no error. The
page was held from startup and the recipe that says what to do with it was not: PLAYTEST-109's
rule was written about pages and nobody asked it of the JSON beside them.

**Built.** The recipe is read in the first build and held in a static for the life of the
process; `manifest_reads()` counts the reads and `tests/test_ground_layers.gd` asks that two
builds make one. A sweep of `src/` for `FileAccess`, `load()` and `DirAccess` found no other
read that repeats during a run: `AtlasLibrary` reads its region table once and its pages at the
two moments, the save is read at boot and written between days, and telemetry writes.

**Rejected:** a rule that the orchestrator checks for a running game before updating the
checkout — *"checking for a running game shouldn't be necessary"*. The silent fall back is
PLAYTEST-110's and goes with that item.
