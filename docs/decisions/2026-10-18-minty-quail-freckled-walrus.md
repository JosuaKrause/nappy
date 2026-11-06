# minty-quail — The atlas suites read the library's load and release off the run log, not its accounting (tests through public seams) · 2026-11-05


minty-quail's `tests-unseen-reads.md`, the atlas build, under the player's rule that a public member
only tests call is deleted where possible, the tests going through a fake or what the game shows
(curly-rabbit #1095), and `tests-hold-nothing.md`'s findings in the same suites.

**Built.**
- The atlas suites read the library's load and release discipline off the run log: the library
  writes one `texture` line when it reads a page from disk and one when the last reference lets it
  go (`docs/TELEMETRY.md`), and a test helper, `tests/atlas_page_log.gd`, opens a memory log and
  answers loads, releases, what is held and the loading moment per group. Sharing a page gives one
  load line; freeing its holders one at a time gives no release line until the last. Region names
  are read off the region table the bake writes (`tests/baked_regions.gd`), and the interior's tiles
  off each built tile source's own region.
- Deleted from `src/`: `AtlasLibrary.is_resident()`, `AtlasLibrary.last_load_moment()` with the
  table only it read, `AtlasTable.region_names()`, `PosterArt.region_names()`,
  `InteriorTileSet.region_name_for()`.
- The audit's findings in `test_atlas_events.gd`, `test_atlas_loading.gd`,
  `test_atlas_stroller_crowd.gd` and `test_interior.gd` were checked: those that held went (the
  stroller's tint tables read back, the indicators' group, the rig's group counts, the interior's
  walkable kinds read back), and the dog's picture count and the interior's single entrance became
  guards that a sweep checked something.

**Kept.** `AtlasLibrary.region_name_for()` and `illustrated_path_for()`, which the bake calls.
`is_acquired()` and `reference_count()`, which three suites outside this build still read
(the item says which). The interior's one blow of steam costing 40 to 50 points, which the audit
flagged as a band read back: it measures a blow's outcome against the player's own target
("steam should be 40 to 50", woolly-penguin #747), not a constant.

**Open to overturn:** the run log as the seam (a loader handed to the library would need a `src/`
hand-in only tests use, and page identity alone fails because the engine shares one cached page
texture between libraries); keeping the steam band.
