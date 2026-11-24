# minty-quail — A building is handed its roof extension, tint, size, library and roof layer (city scene pass, C1b) · 2026-11-23


`Building`'s `roof_extension_rows`, `tint_variant`, `footprint`, `atlas` and `roof_object_parent` are private
(`_roof_extension_rows`, `_tint_variant`, `_footprint`, `_atlas`, `_roof_object_parent`). Their writers are
`extend_roof_over()` (`City.assign_roof_extensions()`, rebuilds), `share_tint()` (`City._share_courtyard_tint()`,
redraws), and the existing `stand_on()`, `equip()` and `put_roof_objects_in()`. Each `@export` setter's work moved
into its writer and the `@export`s went, since no scene sets them. No reader was added: the suites read what the
building draws.

**Chosen.** A suite hands `RoofReads` the extension and the roof layer it knows (`units_of(building, extension,
parent)`, `tallest_of()`, `on_the_interior()`, `extension_of()`), and `FrontReads.watch()` the library the building
draws from. Where a suite did not itself hand an extension, it reads it off the drawn roof
(`FrontReads.roof_extension()`: the roof rows painted over each column less the building's own). The tint is read
as the colours the front paints wall and roof in (`FrontReads.colour_of()`), compared across the pieces of one
courtyard lot.

**Rejected.** A reader on `Building` for the extension, the tint or the size: nothing in the game reads them back.

**The unextended-roof sweep.** `test_city_buildings.gd`'s sweep reads the extension off the drawn roof, so that
check alone does not fail when `assign_roof_extensions()` stops handing the extension (every roof
then reads as unextended and its units on the extension are filtered out); the sweep gained a check that it met extended roofs.

**The lazy probe.** `probes/lazy_scenery_measure.gd` measured the roof's north overhang from the extension and the
footprint it read off the building. It reads the building's own scenery bounds now and takes off the two tiles of
margin the bounds keep, so `max_roof_north_overhang_px` is the same 96 on the cities it measured, and its
`roof_layers` are the same on both seeds (287 and 294).
