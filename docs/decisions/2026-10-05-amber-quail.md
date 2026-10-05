# amber-quail — The test leak was the finale suite's escape section · 2026-10-05

Filed from [feathery-lynx](../playtests/2026-10-05-feathery-lynx.md) (inbox #583): a local full run
in four shards failed `test_frame_record` ("a played frame is kept"), `test_invincible` ("and
excitement rises too, against the same source") and `test_orientation`'s two rotated-touch checks,
each passing alone.

**The cause was `tests/test_finale.gd`.** Two of its tests,
`_test_a_resumed_escape_opens_on_the_title_before_its_first_brief` and
`_test_a_handover_does_not_open_on_the_title`, call `finale.begin(BUILDING)`, which reaches
`main._on_finale_section_started()` and writes the section onto `GameState.escape_section`; neither
put it back, so every suite after it in one process started mid-escape. Found by printing the
section after each test. **Fixed where it is left**: both tests save and restore the section, as
the held-restart test below them already did, rather than the three failing suites resetting it at
their top, which would have left the next suite after the leak to fail the same way.

It is the same leak as M100's item "`test_finale.gd` leaves `GameState.escape_section` set" (the
three sabotage checks of `test_resistance.gd` run after it), which the same fix closes:
`tools/test.sh finale resistance` passes.

**Measured.** `./tools/test.sh finale frame_record invincible orientation` failed the four checks
before the fix and passes after. `./tools/test.sh --shard 4/4` no longer reproduces it on `main`:
the shard plan has moved with `tests/suite_costs.txt`, so none of the three suites shares a shard
with `test_finale` any more; the explicit suite list is the reproduction.

**Chosen while building, open to overturn:** the section is restored in each of the two tests,
not once in the suite's `run()`.
