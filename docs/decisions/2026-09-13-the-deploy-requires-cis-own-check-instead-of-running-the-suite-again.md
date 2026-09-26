## The deploy requires CI's own check instead of running the suite again · built 2026-09-13

*(2026-09-13: "release runs the tests again as well in a single worker. can we make deploy
contingent on previous test flags passing? then we don't need to redundantly run tests again for
it"; and, on the shape of it: "the shell script here should not be the arbiter of ensuring the
green flag since it can be bypassed. I'm saying whether the deploy CI can require other CIs to be
completed on the same commit".)*

**What changed.** `.github/workflows/deploy.yml` no longer runs `tools/test.sh`. Its first job,
`verify`, asks the API for every check run named `test` on the tagged commit — the check
`ci.yml` registers from its eight shards and its gates — waits while one is still running, and
fails unless all of them completed well; `build` needs it. The boot check stays in `build`
because its import pass is what leaves a fresh runner's resources imported before the export
reads them, and it costs seconds.

**Why a check-runs query and not something built in.** Actions has no `needs` across workflows.
A `workflow_run` trigger fires when `ci` finishes, but `ci` runs on branch pushes and pull
requests and knows nothing about the tag, so the deploy would have to find its tag afterwards;
an environment protection rule can require reviewers or a branch pattern but not a status
check. Querying the commit's check runs from inside the deploy is the standard shape, and it is
the same read `tools/release.sh` already makes before tagging.

**What stands behind it.** The `version tags` ruleset requires the `test` status check on the
commit a `v*` tag points at, so a tag on a red or untested commit is refused at the push,
server-side, whatever a local script does. The `verify` job is the workflow's own copy of that
guarantee: it makes the dependency visible in the deploy's log and keeps the deploy correct on
its own if the ruleset is ever loosened. `release.sh`'s wait on the same check is a courtesy to
the operator, never the gate.

**Why the suite was run twice before.** The comment it replaced said `ci.yml` had no branch or
tag filter, so it fired on a version tag too and neither workflow waited for the other; `ci.yml`
has since been filtered to `main` pushes and pull requests, so a tag push runs only the deploy,
and the reasoning for re-running had lapsed without the step being removed.
