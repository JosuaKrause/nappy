priority: bug

# plaid-goose — The Hard Mode box catches like the other buttons · filed 2026-10-17

[fluffy-kestrel](../../playtests/2026-10-17-fluffy-kestrel.md), #740, "Cannot select hard mode":

> Hard mode should have the same 5% extension over the box and text as other buttons

**The rule asked for.** The Hard Mode checkbox on the title screen catches a press over its box and
its label text grown by 5%, the same as the other buttons, whose catch is the larger of their old
catch and 1.05 times their drawn size
([calm-pelican-11](../../decisions/2026-10-10-calm-pelican-11.md), "the 5% button reach is a minimum,
and no catch shrank"; `ButtonGeometry.CATCH_SCALE`, 1.05). The player reports that today Hard Mode
cannot be selected.

**What a read of the code found, not yet reproduced.** The checkbox is not a `ModeButton` and does
not use `ButtonGeometry`: `TitleScreen.hard_mode_target()` is the drawn box and label, at
`_HARD_MODE_SCALE` (1.5), grown by a fixed `_HARD_MODE_REACH` (28 design px) on every side, and
`tests/test_run_checkpoints.gd` passes a press, a click and the `H` key on it. So the catch looks
larger than 5% already on paper, and the cause of "cannot select" is still to be found on the
player's own input: candidates are a press that never reaches it (a mouse click ignored when the
browser reports a touchscreen, as `_touch` gates it), the box having no hover or pressed look the
other buttons have, or the box being shown only on a new game's title (not after an ending or on a
resumed save). Each is a reading, not confirmed.

**Open for whoever picks it up**, to ask the player where it does not reproduce (the
playtest-feedback rule: a bug the player filed is confirmed by the filing, and a desktop rig that
does not show it has only failed to see it): on which device and input selecting failed, and on
which title (a new game's first, after an ending, a resumed save).

Item: [the-box-catches-five-percent-over-box-and-label.md](the-box-catches-five-percent-over-box-and-label.md).
