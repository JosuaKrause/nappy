# The numbers from before the refactor are captured while the old tree still runs

**The ask.** The entry remeasures once, at the end (inbox #813 in curly-moose), comparing "main and the
refactor's head", but the refactor merges into main as it goes. Shown the design review's finding
that "the single remeasure at the end has no stored 'before'. No baseline commit is named and no
winnability or route-cost numbers from before the refactor are saved. Capturing them now blocks
nothing", the player: "sure" (inbox #1268).

**Read as:** the before-numbers are measured on the tree from before the refactor and kept in the
repository, so the end remeasure has something to compare with. *The specifics are the
orchestrator's, proposed and open to the player's correction.*

**Build:**

- **The baseline is `v0.29.0`**, the tree this entry's review read. It is checked out in a scratch
  worktree and measured there; today's `main` is measured the same way beside it, so the two
  columns come from one machine on one day.
- **What is measured**, each by a probe that runs on both trees (a probe written for today's tree
  that the old tree cannot run is rewritten to ask only what both have, and the rewrite is noted):
  winnability across seeds and days; what a route costs to walk; the frame time and the crowd's
  tick on a walked day; the dawn's planning time; and how many of each event row a city holds a
  day, by view (`tests/probes/placement_rows.gd` on main, its counterpart on the old tree).
- **Where it is kept:** a folder under `docs/evidence/` with a README naming the two commits, each
  command, the seeds and the machine, and one table per measurement with both columns, kept as the
  run printed them (**verify**, "experiment evidence").
- **Two more readings later, in the background:** winnability and frame time on `main` when
  placement closes, and again after the events' field-read conversion, each added to the same
  folder as a third and fourth column.
- **Nothing is judged here.** A number that moved is listed for the end remeasure; no step waits on
  a reading.

The script that compares the placement rows of two trees (the record grassy-magpie states its rule;
it has been run by hand at every placement step and lives outside the repository) becomes a
`tools/` entry point in this item, since it is a manual sequence done more than twice (woolly-finch
23), with its row in the using-tools catalogue.
