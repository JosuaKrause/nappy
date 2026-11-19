# The crowd asks a focus source where its patch stands

**The change.** The crowd (the walkers and cars, simulated only in a patch of streets around her)
takes a focus source, a dependency handed in that answers where the patch stands. `main` hands one
that answers with her position; a test hands one that answers with a fixed point it sets. Where the
patch stands then follows the source on every tick the crowd takes, the rigs' `step()` included, so
the patch moves apart from who she is and from the half of the live tick that shoves, warns and
strikes her. `Crowd.set_focus()` is deleted, and every test that called it hands a focus source
instead.

**What stays the same.** Play: in the game the source answers with her position, which is where the
patch already follows her. Proposed, not asked for: the source is read once per tick, at the point
where the live tick reads her position today, so the order of the patch's move against the shoves
and strikes does not change.

**Where it is held.** `Crowd.set_focus` leaves `tools/test_only_members.txt` and the list in
minty-quail's `tests-unseen-reads.md`; the crowd's suite holds that the patch follows the source on
`step()` and that the game's source follows her. **crowd-traffic** and **designing-classes** govern the
change.
