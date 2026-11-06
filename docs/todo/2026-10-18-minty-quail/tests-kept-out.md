# Tests that hold nothing are kept out

**The ask.** After asking for an audit of the tests for checks that hold nothing, and quoting back
the orchestrator's list of the four kinds (a state only the test can create, input the game does
not control excepted; a design decision read back; a check that cannot fail; a duplicate), the
player: "let's make sure those tests also won't enter the codebase again" (curly-rabbit #1097).

**Read as:** a new test of any of the four kinds is stopped before it merges, by a check where a
script can see it and by the rules every builder and reviewer reads where it cannot.

*Proposed by the orchestrator, not asked for, open to the player's correction:*
- **verify**'s testing policy names all four kinds, the check that asserts back what the test set
  itself among them, and the rule that a member only its own file and the tests use is internal
  (curly-rabbit #1098; `tests-own-class-members.md`), keeping its "three that look prunable and are
  not" as they are; **pr-review**'s code checklist names the four and points at that policy, since
  the reviewer is who catches the three a script cannot.
- A CI check in the `gates` job fails a test that reads a public member no other file under `src/`
  uses (a caller under `src/dev` counts; a caller in the member's own file does not), with today's
  such members on a list that only shrinks and a group of members kept public with their reasons.
- The removals themselves are `tests-hold-nothing.md`'s, and the underscores
  `tests-own-class-members.md`'s, not this item's.
