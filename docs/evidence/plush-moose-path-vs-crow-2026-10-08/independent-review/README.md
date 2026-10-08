# Independent PR 588 completion checks

Reviewer: Codex, codex-reviewer identity. Source: b0dfe0bc7e9ffb59aeaa9d53f2174250e3208292,
2026-10-08, macOS arm64, Godot 4.7.2.stable.official.ed1daf0bf. Headless only, no-save.
These are correctness checks, not performance measurements. No full local suite was run.

The exact existing day-11 test is called by `review588_mast.gd`, without rewriting its setup
or assertions. It passes 9 checks against unchanged source. Applying `mast-mutation.patch`
suppresses only the production `_follow_her_between_masts()` call. The same test then fails
4 of 9 checks: handoff to the touched mast, completion, silencing that mast, and its scar.
The mutation was removed before all later checks.

`measurement.patch` prints each candidate at every retarget after the nearest field finishes.
It builds a separate production ArrowField for each candidate to read that candidate's walking
distance at the player's tile. It changes no chosen target, city geometry, or recipe timing.
The final companion recipe's file SHA-256 is
5ab74e83213439ce11eb7597093e17950d839e70cb1a01224f94ca7704f50afa;
the runner's normalized recipe hash is
af2a68153f64536a2df83441ce30b53e39ff40f0d9c19a1063e3c2f2cba6c4ad.
The first sampled retarget is at elapsed 2.467s, player (2961.199,2256):

| Candidate | Position | Crow px | Walking tiles | Selected |
|---|---|---:|---:|---|
| Authored pacing man | (3366,2384) | 424.556 | 26 | no |
| Task man | (3344,1808) | 589.271 | 23 | yes |

Subsequent samples through 3.683s retain the 26-versus-23 walking ordering and selected task
man. The moving man's exact crow distance depends on sample timing; this does not reproduce
the historical 434.10px sample verbatim. The ordering the picture claims is reproduced.
`measurement-results.log` retains every measurement line. The complete diagnostic run has no
engine ERROR/WARNING lines and its recipe observations pass; the original author diagnostic
with sandbox errors is separate evidence and was not used as a clean pass.

After removing the instrumentation, `review588_arrows.gd` and `protest` pass 62 checks.
The focused driver calls the committed all-task-arrow, wall/path-distance, switching,
four-versus-three-tile hold, freed-instance, and single-target regressions. `check.sh` and
`lint.sh` pass. A fresh-checkout atlas bake first emitted its documented missing-global-class
bootstrap diagnostics; the subsequent import and boot completed normally. The focused test
and recipe runs contain no engine diagnostics. The final recipe was run again after removing
the instrumentation: playback completed and both offered/arrowed observations passed.

## Reproduce

Use a fresh scratch checkout and a new output directory; do not run the mutation in a live
author checkout. Fetch `refs/pull/588/head` from origin before checking out the full revision
above, so the historical commit is reachable after the feature branch is deleted. Configure
`GODOT` if the engine is not at the wrapper's macOS default. The commands below assume this
evidence folder's absolute path is in `proof`, and the working directory is the scratch
checkout at that revision. Sparse checkout may exclude docs/reference, docs/style-references
and docs/evidence except this PR's path-vs-crow folder and the files CI's sparse gates retain.
Compare free space with `tools/lib_disk_headroom.sh`'s measured worktree peak and reserve
before creating the checkout. From a checkout containing this evidence, create it with:

```sh
proof_repo=$(git rev-parse --show-toplevel)
proof="$proof_repo/docs/evidence/plush-moose-path-vs-crow-2026-10-08/independent-review"
scratch="$proof_repo/.claude/worktrees/review588-reproduce-$(date +%s)"
git fetch origin refs/pull/588/head
git worktree add --detach --no-checkout "$scratch" b0dfe0bc7e9ffb59aeaa9d53f2174250e3208292
git -C "$scratch" sparse-checkout set --no-cone --stdin <<'PATTERNS'
/*
!/docs/evidence/
!/docs/reference/
!/docs/style-references/
/docs/evidence/**/*.svg
/docs/evidence/m159-event-shape-cache-2026-09-29/measure-native.py
/docs/evidence/m159-danger-prediction-reuse-2026-09-29/measure-native.py
/docs/evidence/plush-moose-path-vs-crow-2026-10-08/
PATTERNS
git -C "$scratch" checkout --detach b0dfe0bc7e9ffb59aeaa9d53f2174250e3208292
cd "$scratch"
```

```sh
./tools/check.sh
mkdir -p tests/probes
cp "$proof/review588_mast.gd" tests/probes/
./tools/test.sh probes/review588_mast.gd
git apply "$proof/mast-mutation.patch"
./tools/test.sh probes/review588_mast.gd  # expected exit 1, four failed checks
git apply -R "$proof/mast-mutation.patch"
git apply "$proof/measurement.patch"
result=$(mktemp -d)
./tools/scene-recipes.sh --recipe docs/evidence/plush-moose-path-vs-crow-2026-10-08/day06-path-vs-crow.json --output "$result"
rg REVIEW588 "$result/day06-path-vs-crow.log"
git apply -R "$proof/measurement.patch"
cp "$proof/review588_arrows.gd" tests/probes/
./tools/test.sh probes/review588_arrows.gd protest
git diff --exit-code -- src/resistance/resistance_director.gd
```

Keep the new results in their fresh output directory. After both patches are reversed and
owned processes stop, remove only the two copied probe files, then remove the clean scratch
worktree through `git -C "$proof_repo" worktree remove "$scratch"` from outside it. A dirty
checkout is retained for inspection, never force-removed.

Limits: no new native pictures; the committed day-6 still and switch pair, day-13 arrow,
and single-mast still were inspected. There is no several-mast screenshot, as explicitly
disclosed by the PR. No browser or performance rerun; CI remains a separate merge gate.
