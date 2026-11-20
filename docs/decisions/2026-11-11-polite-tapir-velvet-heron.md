# polite-tapir — The baseline's reading with placement closed · 2026-11-20

**What was asked.** polite-tapir's `baseline-measurements.md`: the before-numbers are captured while the old tree
still runs (the player: "sure", inbox #1268 in olive-ferret), and a reading of winnability and frame time is taken
when placement closes, added to `docs/evidence/minty-quail-baseline-2026-11-09/` as a further column, nothing judged.
Placement closed with #1548's merge, commit `4da1e5285`.

**What was built.** Every measurement of the first reading was run again at `4da1e5285`, one Godot run at a time with
the machine's load recorded, and its figures are the README's column "placement closed (4da1e5285)", with every raw
output under `raw/` and `raw/timed/` (#1576; a Haiku agent measured, a Sonnet agent got the two figures the first
pass could not). Two probes needed copies for this tree, each with a header saying what changed:
`probes/dawn_planning_time_placement_closed.gd` (the scheduler's API moved: `build_day()` takes a `DawnContext`, and
the day's units are drawn as she comes near them, so the copy times the dawn's plan and the drawing of every unit
apart, their sum being the like-for-like figure) and `probes/entity_frame_profile_placement_closed.gd` (the rig's walk
north loses the day to a leaf blower on its line at this tree, so the copy adds `--invincible`; the README says the
earlier columns ran without it). The README's sentence that the crowd's raw files had their hash chains removed was
false for every set and is corrected; no existing number changed.

**Not done.** The comparison scripts were not run on the new column, since both name their samples in code.

**The item.** `baseline-measurements.md` keeps one reading, after the events' field-read conversion.
