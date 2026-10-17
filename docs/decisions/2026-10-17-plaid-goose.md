# plaid-goose — The Hard Mode box takes a tap and a click, over its whole box grown 5% · 2026-10-17

[fluffy-kestrel](../playtests/2026-10-17-fluffy-kestrel.md), #740, "Cannot select hard mode": "Hard
mode should have the same 5% extension over the box and text as other buttons". Then (inbox #746 in [woolly-penguin](../playtests/2026-10-17-woolly-penguin.md)):
"all of this was on phone"; "I see the hard mode selection after restarting the game (fresh save)
but I cannot click on it locally either. I clicked on the text and the button. the whole bounding
box should trigger"; "+5% of course".

**The cause.** No tap and no click ever reached the box, on a phone or a desktop. Godot's GUI pass
runs before `_unhandled_input()` and ends a press at the topmost `Control` under it whose
`mouse_filter` is STOP; the title's `BottomScrim`, a `ColorRect` at Godot's default STOP, lay over
the box. The three mode buttons still worked because their columns are containers, which default to
PASS. `tests/test_run_checkpoints.gd` called the handler directly, skipped the GUI pass, and passed
throughout. The coordinates, the touch gate and every `_input` handler were ruled out.

**Built (PR #753).** The title's `TopScrim` and `BottomScrim` ignore the mouse; nothing drawn
changes. `ButtonGeometry.margin_rect()` grows a drawn rect to 1.05 times its size about its centre,
and `TitleScreen.hard_mode_target()` is the drawn box and label grown each way by the larger of that
and the old 28 design px (28 is larger at this size, so the catch did not shrink — the
[calm-pelican-11](2026-10-10-calm-pelican-11.md) rule). Taps sent through the engine on a landscape
phone, a rotated portrait phone and a desktop mouse each flip the box once, anywhere on the box, the
label, the space between them and the drawn rect's corner; they fail on the old scene. A second test
names any `Control` on the title left at STOP. The godot skill now says a press read in
`_unhandled_input()` must cross every `Control` above it, and how to test it.

**Hard Mode is chosen for a new game only.** The box is shown only on a title with nothing to
resume; the save is written as day 1 starts, so every later boot of that run gets a title without
it, and a test pins which titles show it. Asked whether a player with a saved run should be able to
choose it, the player ([woolly-penguin](../playtests/2026-10-17-woolly-penguin.md), #746): "yes,
hard mode is new game only. you cannot change in the middle of a run." The line on the resume
title saying a held restart begins a new game was the filer's addition to that option; asked what
it was for, it was left unbuilt.

**Choices open to overturn:** the catch through `ButtonGeometry` (proposed in the entry, not asked
for); the two margins combined with `Rect2.merge`; no hover or pressed look added, since the cause
was not missing feedback.
