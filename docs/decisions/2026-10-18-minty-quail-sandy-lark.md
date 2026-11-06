# minty-quail — The main scene's, save's, title screen's, HUD pieces', visit counter's and stroller's members only their own class used become internal · 2026-11-06


minty-quail's `tests-own-class-members.md`, the underscore pass, for the main scene, the save, the
title screen, the return window, the excitement halo, the mode button, the meter bar, the visit
counter and the stroller: a public member only its own class and the tests use becomes internal and
its tests move to what the class does outward (curly-rabbit #1098), and one with no reader left is
deleted (curly-rabbit #1095).

**Built.** The main scene's day, escape-section and escape-part builders are internal: the part-word
test boots the real main on each `--start-escape` word and reads where she stands, and the sections
test reads the booted escape's clock. The save's `file_data`, `has_save` and `uses_save` are
internal and `FILE_KEYS` is deleted; the suites read the scratch file a write leaves, the
checkpoint suite reads the fields off `run_data()` since a run with an ending is never written,
and the scene-recipe runtime suite saves to a scratch path. The title screen's hard-mode box and
the return window's input check are internal, read through the box's node and a real press on each
button. The halo's colour, brightness and selection are internal, read through the rims a real halo
lights over real frames (`tests/halo_rig.gd`'s `lit_among()`). The visit counter's charger names
are read off the events it sends. `Stroller.indicator_sources` is deleted and `sources_by_group` is
internal, read off the page she draws as each parent. Comments and docs that named the renamed
members name them as they are.

**Kept public**, each with its reason beside its line in the list: `VisitCounter.listen` and
`send_through`, the hand-ins the counter's `_ready()` fills with the real bus and outbox where a
test hands fakes (`tests-public-seams.md`'s Build paragraph); `GameSave.moment_result` and
`ReturnWindow.on_web_event`, which only a web export reaches; `ModeButton.hold_progress`,
`MeterBar.displayed_value` and `displayed_fraction`, and `Stroller.baby_cue_aside` and
`baby_cue_lift`, which feed only a `_draw` that a headless run never shows. Open to overturn.
