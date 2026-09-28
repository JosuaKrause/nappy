# leafy-finch-2 — CI takes the mechanical review · built 2026-09-27

*([bouncy-heron](../playtests/2026-09-27-bouncy-heron.md), statement 9: "what I want is a CI check
that does what the reviewer currently does automatically. we should get as close as possible to
that. the reviewer still needs to verify the correctness of those changes anyway. the CI is only a
help" · statement 20: "only the "heavy game tests" not only the heavy "game tests". I mean all game
tests that are not checking doc consistencies etc." · statements 7, 8, 10 to 12)*

**Built (PR #425).** A first CI job, `classify`, sorts a pull request by the files it changes into
queue-only, docs-only and touches-code, never by its title. A docs-only PR skips every test of the
game (the boot check, the two runner fixtures and the eight suite shards) and runs every check of
the repository's own consistency: the doc lint, the CLI help test, the hook and agent-role tests,
the Python gate, the telemetry-kinds check (moved out of the Godot suite into a script, since it
reads only `docs/TELEMETRY.md` and the code) and the cost table's check, which needs Godot and runs
in its own job beside the others. `test` stays the one check the rulesets require, and fails if a
job that ran failed or if the game's tests were skipped on a PR not classified docs-only.

Four checks read the PR itself, each a script under `tools/` with its own tests: a queue-only PR
changes no existing playtest and accounts for every deleted item (a record for its entry, a
`Dropped:` line quoting a playtest verbatim, or a move) and every deleted review item (a playtest
naming it); each `Filed from #N` note is the player's own, or the capture script's (the
orchestrator's or Codex's coder identity, with the label `captured`), and its body is copied
verbatim into an added playtest; a PR touching `src/` or `tests/` resolves a queue item and files a
record, or says `No queue item: <reason>`; and no PR adds a handoff file. Each reads the
description through the API when it runs, so a corrected description is re-checked by re-running
the job. The **pr-review** skill's queue-update review is now a faithfulness review on Sonnet: the
five questions for each entry added or reworded, flagging rather than resolving, and a check of
what CI cannot see (that a record really covers the deleted item, that a drop's quote says what it
claims).

**Shown on real runs:** a docs-only scratch PR skipped the game's tests with `test` green, and went
red and green again as its description was changed with no push; a code scratch PR ran every job.

**A known gap, as filed:** the queue-update check accepts any record whose name starts with the
entry's, so once one PR of an entry has filed its record, a queue-only PR can delete any other item
of that entry with CI green. The faithfulness review is what catches it: it confirms the record
actually covers the item deleted.

A `.gdignore` anywhere makes a PR not docs-only, since it decides what Godot imports. A handoff
file is one the PR adds whose own name starts with `handoff`, in any case; a name that only
contains the word passes, by the player's call, since both past handoff files are gone and the
review catches the rest.

**Open to overturn:** the handoff rule's narrow form; the label `captured` for a captured note (the
orchestrator's choice); how "verbatim" is normalised (quote markers dropped, whitespace runs
collapsed, everything else counts); that only a note's body is checked, not the player's comments on
it; the `Dropped:` line's accepted separators; that the playtest rule runs on queue-only PRs only;
that the suites comparing code with assets (atlas, ground layers, scenery crops, dev flags, the
render-loop scan) stay game tests; and that `docs/TELEMETRY.md` and `docs/COSTS.md` still count as
not docs-only, though the moved telemetry check and the always-run cost table remove the reason for
both.
