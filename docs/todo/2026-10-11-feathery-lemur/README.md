priority: now

# feathery-lemur — A held input carries her on through a gatehouse's release · filed 2026-10-11

[velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #697:

> another bug I noticed. with the gatehouses if I don't lift my finger during the move I don't expect the movement to get reset. so, only reset if I lift my finger. basically keep updating navigation

Asked whether a key held on the keyboard should do the same:

> Keyboard holding is the same as finger holding. If I don't lift it I expect it to remain active

**What it replaces.** [downy-lark](../../decisions/2026-10-10-downy-lark.md), built from the
player's "let's reset the movement to 0 when leaving so the player has a choice" (inbox #667),
records as *"Proposed at filing and built, open to the player's correction: a held input is ignored
until released or changed, in every control mode, for every `redetains` hold."* This is that
correction. The reset when the hold lets her out stays for an input that was lifted, so she still
stands still for a player who let go; an input still held through the release keeps steering her.

**Where it is built today.** `Stroller.show_after_inspection()` zeroes her velocity and remembers
the raw input held at the release, reading it as zero until it is released or changes; it calls
`TouchControls.stand_still_after_hold()`, which drops the heading a tap or a drag locked in
("A finger still down chooses again by moving; one lifted or held still does not").
`tests/test_checkpoints.gd`'s `_test_she_stands_still_when_a_hold_lets_her_out` holds the current
behaviour for a key, a tap and a joystick drag. `docs/MECHANICS.md`'s hold paragraph describes it.

The work is [a-held-input-keeps-steering.md](a-held-input-keeps-steering.md).
