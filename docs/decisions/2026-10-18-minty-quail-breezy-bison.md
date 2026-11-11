# minty-quail — The field-read check passes a read that only moved (minty-quail, tools) · 2026-11-10

**The ask.** The field-read check was to be made to work (inbox #1268 in olive-ferret), and the
refactor goes module by module with code moved into the classes it belongs to (the entry's
README, "Order"). The check's `--base` mode failed two kinds of move that add no read: code moved
into a file the pull request adds, and an inner class lifted into a file of its own, whose fields
the check could not see before. The placement track's next steps (the plan record lifted out of
the scheduler as `EventPlan`, the scheduler's breakup into `PlanBuilder` and its phases) are both
kinds; on a copy of the tree the lift alone failed about 93 lines (83 under the lifted class, 10 of the row's fields read from its new file). The planning agent's proposal.

## What was built

`tools/check_field_reads.py --base` passes an added line of `tools/field_reads.txt` in three cases
and no other:

- **A renamed reader file**: a line of the same class and field removed and git reporting the file
  renamed (as before).
- **Code moved into a new file**: the reader file is new since the base, and over the files that
  differ between base and head the head's uses of that class's field are no more than the base's,
  counted the same way on both trees, one count per class and field, so a file split in several
  passes.
- **An inner class lifted out**: the line's class is a file new since the base and no git rename of
  an existing class file, and it declares every var of one inner class that declared the field at
  the base and that the head no longer declares; a lift that drops a var fails. Nothing is counted
  here, since the base could not see an inner class's fields, so a lifting diff's new readers pass
  uncounted and review reads that diff for them.

Every other added line still fails with the message it had: a new file reading a field no changed
file read, a move that also adds a use, a new class with a public var read from outside, a new class
that declares only some of the vars of an inner class that left the diff. A new class that declares
them all is taken for that class lifted, a one-var inner class included, and one such inner class
vouches for each new class that declares its vars; each such added line is a visible line of the
list, which review reads. A change
to the checker itself still compares nothing (`checker_changed`). The docstring, the `--base` help
and the list's generated header say the rule; the designing-classes skill's sentence on the check
says it too, and lists the rule as proposed. `tools/test_check_field_reads.py` holds a passing and
a failing case for each rule, each with the mutation that would fail it (eight mutated checkers,
each failing a case), and one case end to end through a temporary git repository. The base's tree
is built only when an added line is neither listed nor paired by a rename.

Whether the list may gain a moved read's lines was put to the player on the board
(moved-reads-list), since their "yes" was to a list that only shrinks (inbox #1182 in
gray-dolphin). Shown both ways, a moved read passing with its lines added, or every pull request
that moves code converting the reads it moves, the player took the first (inbox #1350). Which moves
count as a move (a reader file renamed, code moved into a new file with no more uses, an inner
class lifted out) stays the planning agent's proposal.

## Choices the builder made, open to the player's overturn

- **The changed files are found by comparing the two trees' `src/` texts**, not `git diff`, so an
  untracked file counts.
- **The count is a net over the changed files**, as "no more than" words it: a use removed in one
  changed file offsets one added in a new file.
