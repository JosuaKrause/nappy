# minty-quail — The resistance and checkpoint suites stop calling members only tests call · 2026-11-05

minty-quail's `tests-unseen-reads.md`, the resistance and checkpoint owners' build, under the
player's rule that a public member only tests call is deleted where possible, the tests going
through a fake or what the game shows, and kept only where the information cannot be had otherwise
and the test needs it (curly-rabbit #1095); and `tests-hold-nothing.md`'s findings in the same
suites.

**Built.** All eighteen members went, none kept: `ResistanceDirector`'s `arrow_key`,
`arrow_targets`, `arrow_nearest_at`, `arrow_lead_at`, `arrow_sweeping`, `mast_in_play`,
`mark_tiles`, `reaches_from_home`, `fell_back`, `trap`, `door_position` and `door_axis`, with the
two fields only they read (`_trap`, `_fell_back`); `CheckpointController.guard_after_her` and
`crossing_door`; `ResistanceHappenings.raid_vans`, `raid_beat` and `is_closing`; and
`CordonTape.body_rect`. The tests ask instead, mostly through a shared helper,
`tests/resistance_reads.gd`: the arrow by where its tip stands (`red_arrow_target()`) and the live
instances there, settled by 240 director ticks rather than the private sweep flag; day 11's masts
by standing beside each and seeing whether the task follows her; day 9's door by deriving it from
the region plan; the guard and the robber as the live `door_guard` and `robber_giving_chase`
instances; the crossing warning as a gatehouse guard's raised hand; the way home as a
`ReachabilityGrid` over `reach_obstruction()`; the mark tiles as the map's alley mouths through
`mark_tile_of()`; a fallback by the run log's own line through a recording trace, or on day 11 by
the task standing on a mast the city already had; the raid's points off a first arrival then
removed; the cordon from `happenings.cordon`, and a tape's body from its collision shape.
`docs/ARCHITECTURE.md` follows, `test_checkpoints.gd` and `test_scene_recipe_task.gd` changed the
few lines that read the removed members, and six probes read the director's private fields; the
placement fingerprint probe no longer prints "fell back", so its output differs from earlier
recordings on that line.

**Audit findings.** The arrow suite's four-tile and three-tile probes, which went red only when
`ARROW_HOLD_TILES` was retuned, went; so did the narrow-reach suite's per-day "has a narrow target"
check. The replacement suite's silent skip is now a check that fails. Day 13's "the arrow field
equals a fresh sweep tile for tile" went with the accessor it read; the walking-distance test still
holds the arrow reading what blocks her.

**Open to overturn, the builder's choices.** The shared helper file; the fixed 240 settle ticks;
probing day 11's masts by walking; the day 9 door derived in the test, a deliberate copy of the
director's rule; the throwaway first raid arrival; removing `_trap` and `_fell_back` with their
members.
