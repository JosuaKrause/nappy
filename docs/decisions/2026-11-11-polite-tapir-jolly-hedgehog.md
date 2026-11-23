# polite-tapir — A save's change is answered on the settled signal · 2026-11-23

**What it is.** Pull request 3 of Fable's design for polite-tapir's standing layer breaks
(`.claude/briefs/designs/polite-tapir-standing-rest.md` in the orchestrator's checkout, not tracked),
section 4: the save indicator (a view) named the observers' `GameSave` for two values of its enum, and
the view and the observers are siblings that name neither the other (inbox #904 in freckled-moose).

**What was built.** The bus's two announcements, `save_written` and `save_deleted`, carry the
operation and nothing else. `GameSave.write()` and `clear()` emit the settled signal
(`save_write_settled`, `save_deletion_settled`) in the same call wherever the answer is known at once
(off the web, or a failure known at once), and a web flush emits it later as before, so every announced
change is settled exactly once; a refused change announces and settles nothing. `SaveIndicator` connects
the announcements to `_begin()` and the settled signals to `_settle()`, and its handler that derived
`kept` from the enum is deleted. The `GameSave` entry of `tools/layer_map.py` is deleted, and the
item's clauses on the indicator with it. `GameSave.Result`, what `write()` and `clear()` return, the
`settled` callable (still called for a pending change only) and the run log's lines are unchanged.

**What it measured.** Off the web the symbol's timeline sees the same two calls, `begin` then
`settle`, in the same order with the same arguments, now from two emissions run back to back inside
one call of `write()` or `clear()`. `test_save`, `test_save_wiring`, `test_run_checkpoints` and
`test_atlas_boot` pass, and `check_layers.py --list` no longer lists the indicator.

**What was rejected.** Moving the enum to `GameEnums` (data) and keeping the `result` argument: it
renames `GameSave.Result` across about fifty test lines and keeps `kept` derived in two places.
