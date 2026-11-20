# The region plan and the gate's state answer through methods

`RegionPlanner.RegionPlan` and `GateState` (`src/routes/region_planner.gd`, the routes, model layer) have their
fields read from outside the file. Each read becomes a method on the class it reads, named for what the caller wants
to know (a yes-or-no field's method takes a new name, **designing-classes**), and each field goes private; the
search for every old name read without parentheses is shown in the pull request (inbox #1385 in silver-tapir).
Whether the two inner classes are lifted into files of their own first is the builder's design question, since the
field-read check cannot see an inner class's readers (`uv run python tools/check_field_reads.py --help`). The suites'
reads are rewritten in the same pull request or, if minty-quail's row 4a script has not run yet, listed `[kept]`
until it does, as rows 2a and 2b of `event-interface.md` did. The readers are listed in the row 3a design's
`inner-class-reads.txt` (in `.claude/briefs/designs/minty-quail-row-3a/` of the main checkout); a builder reruns the
search on the tree it builds on.
