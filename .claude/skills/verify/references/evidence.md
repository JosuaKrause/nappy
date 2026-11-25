# What evidence is checked in

Part of **verify**, and shared with **playtest-feedback**. Read it before committing anything under
`docs/evidence/`: it says which artifacts of a playtest or a rig run are kept and what their folder
records, and what an experiment checks in beside its conclusion. Where gameplay stills, bursts and
run folders go and what a frame may be said to prove is **session-captures**'s.

## Evidence lives in the repo

**Every log, telemetry map or screenshot a doc points at gets copied into `docs/evidence/` in the
same commit as the sentence that points at it.**

`user://telemetry/` is a **scratch directory the player has to be able to empty**, and nothing
prunes it — every `tools/shot.sh` and `tools/check.sh` run adds to it and the game deletes none of
it, so emptying it is the player's routine maintenance. A finding whose evidence lived only there
stops being checkable on a perfectly ordinary Tuesday.

Evidence cannot be recovered by replaying: **a run log that records a player's relevant actions is
not a function of the seed.** Regenerating gives a different run with the same city, so retain that
log when the actions or their order support the finding.

**Copy only the run artifacts relevant to what the playtest or rig was meant to show.** Keep every
artifact needed to support the claim and its limits, including relevant player evidence,
contradictory results and failed trials. Omit unrelated automatic pictures, routine boot output,
logs that do not support the claim or its provenance, and redundant copies. A log belongs when it
proves the actual behavior, preserves non-replayable player input, diagnoses a relevant failure or
supplies provenance that is not recorded elsewhere.

The evidence folder's README or manifest records enough context to interpret and reproduce the
selection: the source revision, command and settings, and the seed and timing when they matter,
plus the claim and its limits. When selected artifacts come from
`user://telemetry/<day>/<run>/`, keep them under the run folder's original name, which carries its
time, seed and commit; the README or manifest makes explicit which files were selected and why.

**In an agent's sparse worktree a new evidence file is committed with `git add --sparse <path>`**,
since the sparse checkout leaves most of `docs/evidence/` out.

## What an experiment checks in

**Keep experimental evidence compact by default.** Check in the question, conclusion and limits;
the runnable probe or reused collector/analyzer and exact rerun commands; source revisions,
collector identity, environment, settings, seed, warmup/window lengths, actual run order and
acceptance criteria; and compact results for every trial relevant to the claim, including failed,
rejected and contradictory trials and their reasons. Preserve the per-run distributions, counts
and workload checks that support the claims, rather than only a pooled average or the best pair.
Relevance follows the question the run or rig was meant to answer: unrelated automatic captures,
generic boot output, irrelevant logs and redundant copies stay in scratch space. Put the conclusion
in the decision record and its evidence under `docs/evidence/`.

Rerun instructions create the required revision checkouts and use caller-relative paths, fresh
scratch directories and a configurable engine executable instead of the author's local paths.
Every named capture revision must also be fetchable from a fresh clone. When it exists only on a
pull request branch that will be squash-merged and deleted, fetch the durable ref first
(`git fetch origin refs/pull/<PR>/head`), then check out the full commit ID it makes reachable;
never assume the reproducer already has the branch's objects locally.

Timed comparisons use clean tracked checkouts: a commit ID alone does not identify dirty
runtime sources. Record hashes of source files an audit can rewrite, and revalidate source and
collector identity after setup and before captures. Run source-rewriting demand audits in
separate disposable checkouts. Historical source-state gaps are disclosed, not filled with
hashes computed after the capture.

**Full profiler streams, expanded analyzer output, build/test stdout and duplicate generated
reports stay in scratch space unless the conclusion needs their original detail.** Retain a
focused original trace or input when it proves a defect, supports attribution that aggregate
results cannot substantiate, or records something the rerun cannot recreate. Keep the smallest
useful data, compress it where appropriate, and explain why it belongs in the repository. A
compact result can record historical medians and tails without promising arbitrary reanalysis
of the original capture. Fresh reruns reproduce the experiment; timing varies between launches.

Before committing, count the evidence files and bytes and report that footprint in the PR.
Verify compact results against the original output before discarding it, remove redundant
copies, and ensure every retained claim is supported by the checked-in evidence. Rerun commands
write into a new scratch directory instead of overwriting the recorded results. Routine test
verification needs its command and outcome, not a checked-in copy of the entire test run.

Player playtests and gameplay captures remain primary evidence under **playtest-feedback** and
**session-captures**; their retention rules apply to those records.
