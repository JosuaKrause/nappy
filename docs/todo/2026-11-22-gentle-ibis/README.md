priority: later

# gentle-ibis — The prediction audit no longer instruments the tree · filed 2026-11-22

**Found** by the agent of pull request #1631 (minty-quail row 4b), whose build of the probe failed.

**What holds.** `tests/probes/m159_prediction_audit.py` rewrites a disposable checkout's `src/events/simulation/event_instance.gd` and `src/crowd/crowd_agent.gd` to count the equivalent sampling requests. It anchors on the text `func expected_gross_at(player_position: Vector2) -> float:` and its generated key reads `def.shape.kind`, `def.shape.half_length` and `def.shape.half_extents`; the event definition has no `shape` field on main now (the row's ground shape is asked through `ground_shape()`). On a clean copy of main the script stops at its first replacement, `assert text.count(before) == 1`, for the missing `expected_gross_at` anchor, before it reaches the `def.shape` text. It is built for the tree the baseline measurements used, which still had both.

**The command that shows it:**

    tools/agent-setup.sh --detach origin/main audit-check
    python3 -I tests/probes/m159_prediction_audit.py <that worktree>     # AssertionError on event_instance.gd

**What the fix must hold.** Either the script instruments a current checkout (anchor and key written against the methods the event instance and the crowd agent have now, `--help` still printing its usage) and a run of the instrumented tree's `entity_frame_profile` carries the counts, or the probe is deleted with a decision record naming why nothing asks for it any more. Nothing runs it routinely, so either answer is the entry's to choose; the header says which tree it fits.
