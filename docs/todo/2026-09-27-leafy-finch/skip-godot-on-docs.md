**A docs-only PR skips every test of the game and runs every check of the repository's own
consistency** (statement 7, and statement 20: "I mean all game tests that are not checking doc
consistencies etc. heavy here implies in general that game tests are heavy. however, currently
some tests are under regular tests that only check the internal consistency of the repo (eg the
handoff guard) those should still happen"). The line is what a check is about, not how long it
takes: a test of the game is skipped, and a check that the repository agrees with itself — docs
with code, rules with hooks, the queue with its records — runs, wherever it lives today.

A PR is docs-only when every file it changes is Markdown or under `docs/`, except three files the
Godot checks read: `docs/TELEMETRY.md` (a test parses it and fails when a telemetry kind the code
writes has no row), `docs/COSTS.md` (`tools/cost-table.sh --check` regenerates it and compares) and
`docs/ARCHITECTURE.md` (`tools/check.sh` watches it for side effects of the import pass).

**Some consistency checks live inside the Godot suite today**, among the game's tests, and so run
only where the suite runs. Building this item sorts every check `.github/workflows/ci.yml` runs
into the two kinds, and a consistency check found inside the suite either moves out to where a
docs-only PR runs it, or the docs-only run keeps the part of the suite that holds it. The sorting
is listed in the PR for the player to read, since which check is which is theirs to correct. Known
so far: the doc lint, the CLI help test, the hook tests, the agent-role test and the Python gate
are consistency checks outside the suite; `tests/test_telemetry.gd`'s check that every telemetry
kind has a row in `docs/TELEMETRY.md`, and `tools/cost-table.sh --check`, are consistency checks
that need Godot; the boot check, the negative fixtures of `tools/test.sh` and the rest of the
suite shards test the game. The player's example, "the handoff guard", names no check that exists
today — a search of `tests/`, `tools/`, `.claude/hooks/` and `.github/` finds none — so the filer
reads it as the check of `no-handoff-file.md`, built as a consistency check; the player has not
confirmed it.

The `test` job, which is the check `main`'s ruleset requires by name, passes on a docs-only PR when
every consistency check passed and the game's tests were skipped, and only on a PR the
classification called docs-only, so a PR that touches `src/` can never skip them. The
classification's flags — queue-only, docs-only and touches-code — come from the first job
described in the entry's `README.md`, and the **verify** and **committing** skills say what `test`
means on each kind of PR.

**Proposed, not asked for:** the sorting above, and whether a consistency check that needs Godot
moves out of the suite or keeps Godot on a docs-only run; the player reads the full list on the PR.
