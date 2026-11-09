# The numbers from before the refactor and from today's main (minty-quail, the baseline measurements)

INTERIM: this README is committed while measurements are still running; it says which are done.

Trees: before = tag `v0.29.0` (6985ac74f), today = origin/main 38ce03823, each a detached scratch worktree.
Machine: Apple, Godot 4.7.2, headless. Load averages were above 28 and above 50 at times during the counts runs
(other agents); the load before each run is in `raw/*.load`.

Status
- 3 placement rows by view: DONE both trees (`raw/placement_rows_*.log`, comparison `raw/placement_comparison.txt`).
- 2 cost table: DONE both trees (`raw/cost_table_check_*.log`, `raw/COSTS_*.md`, `raw/COSTS_diff.txt`).
- 1 winnability and 2 route-cost probes: before DONE; today running (batch order: m129_zero_cost_line, m117_decay, polite_rabbit_wall_costs, then suites).
- 4 dawn planning time, 5 crowd tick and frame time: NOT STARTED (timed, alternating trees, after the counts batch).

Probes cut down: `placement_rows_v0.29.0.gd` (v0.29.0 has no placement_rows; see its header). `placement_roles.gd` makes the one role
table for both trees. `compare_placement.py` is the grassy-magpie script (`placement-remeasure-script.original.py`) with paths
pointed at these logs and its editorial sections removed.
