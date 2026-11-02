# minty-quail — The atlas library is an instance the Sitting holds, over a region table read once (hidden statics) · 2026-11-02


minty-quail's `hidden-statics.md`: the atlas library, the last static read across the whole game. The
item stays open for `StreetNetwork`'s lattice memos.

**Built.**
- `AtlasTable` (`src/visuals/atlas_table.gd`, the data layer) is the region table as an immutable
  value: the regions, the bake mode, the page sizes and padding. `AtlasLibrary` is an instance built
  over a handed table (`AtlasLibrary.new(table)`) holding the pages, the loading window, what is
  resident and the loading moments. The `Sitting` holds the one library, so the pages kept for the
  process and the loading moments survive a held restart; `main` hands it to the city (its
  furniture, its crowd, its events through `EventWorld` and every `EventInstance`), her, the escape's
  interior, the steam grates, the danger edge, the save symbol, the touch controls and the screens
  (`use_atlas()` on the HUD, pause, summary and title). `region()` is one dictionary lookup on a hit.
- Code that needs only a picture's size before any city or library exists (the street trees'
  footprint, the events' footprints, the bollard and closure shapes) reads the table through
  `AtlasTable.baked()`, a memo no caller writes. A node handed no library makes its own when it first
  acquires one; a boot test checks every node in a booted day and escape holds the sitting's library.
- The layer map's `AtlasLibrary` exception, the eight shared-state exemptions and the test-only
  resets are gone.
- A recorded run (seed 4242, `--no-save`, the same walk) shows every draw count, the timed calls, the
  job counts, the page loads and their sizes, and the pages held unchanged from the branch point; the
  draw bucket fell by about 15 µs a frame.

**Open to overturn** (the builder's choices where the brief was silent): `AtlasTable.baked()` as a
process memo rather than a table handed through the scheduler and planners; a node handed no
library making its own; `PosterArt` taking the library on each call.
