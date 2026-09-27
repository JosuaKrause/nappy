**A PR whose changed files are all docs skips the heavy Godot checks, and keeps the light ones**
(statement 7: "only the heavy game checking tests should be skipped"). A PR is docs-only when
every file it changes is Markdown or under `docs/`, except three files the Godot checks read:
`docs/TELEMETRY.md` (a test parses it and fails when a telemetry kind the code writes has no row),
`docs/COSTS.md` (`tools/cost-table.sh --check` regenerates it and compares) and
`docs/ARCHITECTURE.md` (`tools/check.sh` watches it for side effects of the import pass).

On a docs-only PR, `.github/workflows/ci.yml` still runs the doc lint, the CLI help test, the
hook tests, the agent-role test and the Python gate; it skips the Godot download, the boot check,
the cost table's check, the negative fixtures of `tools/test.sh` and the eight suite shards. The
`test` job, which is the check `main`'s ruleset requires by name, passes when the light checks
passed and the shards were skipped, and only on a PR the classification called docs-only, so a PR
that touches `src/` can never skip the suite.

The classification's flags — queue-only, docs-only and touches-code — come from the first job
described in the entry's `README.md`, and the **verify** and **committing** skills say what `test`
means on each kind of PR.

**Proposed, not asked for:** which CI steps count as heavy and which as light, as listed above;
the player's ask is that "only the heavy game checking tests should be skipped".
