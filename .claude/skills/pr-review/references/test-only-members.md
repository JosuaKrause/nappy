# Reviewing a change to the test-only list or its checker

Part of **pr-review** ("Then the code"). Read it when a pull request's diff touches
`tools/test_only_members.txt`, the list of public members only tests read that are let stand, or
`tools/check_test_only_members.py`, the check that reads it. What the check fails and what it counts
as a reader is its own `--help` (`uv run python tools/check_test_only_members.py --help`) and the
header of the list; which members may stay public for a test is **writing-tests**'s ("What a test
holds").

## What CI holds, and what is left to the reviewer

CI fails a new test-only member, a line added to the list's `[no reader]` or `[own file only]`
group against the pull request's base, a stale line, and a `[kept]` line with no reason. Three
things it does not judge are the reviewer's:

- **Whether a `[kept]` line's reason holds**: the player's exception (the information cannot be
  had another way and the test needs it), a hand-in, or a line the check misreads.
- **A diff that changes the checker itself**, which CI exempts from the rule that the two groups
  only shrink, since a better checker surfaces members the old one could not see. The procedure
  below is how its added lines are read.
- **A change to the check's own exemptions in the tool**: `ENGINE_MEMBERS` (a name never counted as
  a read, which exempts it everywhere) and `SKIPPED_TESTS` (a test file not scanned). Each switches
  the check off with no list line and no reason.

What the check cannot see at all stays with the review of the tests: a member whose name is also a
word in another file, and a test of a setup the game cannot reach.

## A diff that changes the checker

For each line such a diff adds to the `[no reader]` or `[own file only]` group, run the base's
checker on the head tree:

1. Copy the base's `tools/check_test_only_members.py`, `tools/check_layers.py` and
   `tools/layer_map.py` into a scratch folder.
2. Run `uv run python <scratch>/check_test_only_members.py --root <head checkout>`.
3. Read its output against the added lines:
   - **An added line it prints nothing for** is a member the base's checker still sees as
     test-only, which a checker change may not list.
   - **A `REMOVE` line**, whatever its reason, is fine: the base's checker does not see the member
     as test-only.
   - **Each `FAILED` line** is a member the base's checker sees as test-only and the head's checker
     no longer does. Check that the new checker is right to drop it, and not that the change hid
     it. A drop that is right, as an example: a test's call of a method on one class is no read of
     a method of the same name on another class, which a checker reading by class sees and one
     reading by word does not.
