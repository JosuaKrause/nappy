# minty-quail — Four more modules' unreached members are deleted · 2026-11-07

minty-quail's `dead-code-sweep.md`, four more modules, in #1223, each a commit of its own; every
member re-checked unreached across `src/`, `tests/`, `tools/` and `scenes/` before it went.

**Deleted.**
- **`AtlasTable.has_group` and `page_padding`** (`src/visuals/atlas_table.gd`), named nowhere, and
  the page record's `padding` entry only `page_padding` read; the bake reads padding from its own
  JSON.
- **`CrowdField.contains`** (`src/crowd/crowd_field.gd`), no caller.
- **`Stroller.family_sources`** (`src/player/stroller.gd`) with `_sources_by_group`, `_paths_in`
  and `stroller_sources`, which only it used. Its one reader, `tests/test_player_presentation.gd`,
  holds a guarantee still true (every picture the rig can draw is a baked region) and now lists the
  stroller's sprite constants itself.
- **`lib_queue.REVIEW_NEXT_RUN` and `inbox.ISSUE_URL`** (`tools/`), named nowhere.

**Choice where the design was silent, open to overturn:** the stroller test kept, listing the
constants, rather than deleted with the member it read.
