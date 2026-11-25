# minty-quail — The small parts main.gd reaches into take their facts through use_ methods · 2026-11-18

**What it is.** A part of minty-quail's `field-reads.md` conversion: fourteen classes whose only
outside reader in `tools/field_reads.txt` was `main.gd`, which mostly wrote a fact into a part after
building it (an atlas, a trace, a timing, a rotation). An Opus builder designed and built it. It
changes nothing in play.

**The pattern.** One `use_*` method per fact, called by `main` on the line where it wrote the field,
so every part gets its fact at the same moment; the names follow the siblings' (`use_atlas()`,
`use_trace()`, `use_frame_timing()`, `use_rotated()`). Constructor arguments were rejected because
the on-screen controls are built from a scene, which takes none, and some facts are handed again
later (the rotation as the window turns, the trace each boot); one configure method per class was
rejected because it bundles facts that arrive at different moments.

**What was built.** `use_trace()` on the building walker, the save, the resistance director and the
route rig; `use_trace_note()` on the atlas library (a callable, since the library sits below the
trace's layer); `use_simulation_clock()` and `use_before_capture()` on the screenshot rig;
`use_the_spec()`, `use_first_day()` and `use_escape_follows()` on the day director, whose
`use_the_day()` calls `use_the_spec()`; the rig lock's question `shuts_out_real_input()`; the
screen-edge badge's `use_frame_timing()` and `use_rotated()`; the halo's `use_frame_timing()`;
`use_atlas()` on the on-screen controls, the save symbol and the escape's building, with
`covering()` and `map()` read through methods. `tests/test_atlas_boot.gd` counts the controls, the
save symbol and the building and checks the sitting's library was asked by each; it fails with
`main`'s three hand-ins removed. `tools/field_reads.txt` lost 21 lines and gained none.

**Left:** `StillWatch.trace` and `TouchControls.rotated`, written by `main` and read by tests alone,
join the item's group of fields only a test reads; the badge's `atlas`, handed through `use_atlas()`,
stays public beside `Stroller.atlas`, since `test_atlas_boot` finds atlas holders by the field's name.

**Proposed, not asked for, open to the player:** the `use_*` pattern; the method names; the badge's
`atlas` kept public; pictures in two suites compared by their baked rectangle.
