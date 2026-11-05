#!/usr/bin/env bash
# Turns on auto-merge for a queue of already-authorized pull requests, or merges one that could
# merge right now, and stops. It does not wait: GitHub merges each PR once its checks are green and
# its approval is in, and a later check confirms that it did (inbox #1068 in gentle-walrus).
#
#   1. per PR, before anything is merged: a closed PR stops the run, a PR already merged is
#      skipped, a conflict with main stops it (turning the PR's auto-merge off), a red check stops
#      it the same way, and a PR that edits the old single-file queue that main has as files stops
#      it before merging, naming the files, since GitHub can merge such an edit cleanly into the
#      new short files; it is converted with tools/convert-queue-edits.py (tools/lib_old_queue.sh)
#   2. gh pr merge <n> --squash --auto     (turns auto-merge on) -- or, when the PR's own
#      mergeStateStatus already reads CLEAN (checks green, no conflict, approved), gh pr merge <n>
#      --squash directly, since GitHub refuses to enable auto-merge on a PR that could merge right
#      now ("Pull request is in clean status (enablePullRequestAutoMerge)") -- the same direct merge
#      is the fallback if auto-merge is attempted anyway and fails with that error
#   3. print, for every PR, what happened and the check that confirms it: the PR shows MERGED, and
#      then tools/prune-merged.sh <branch> retires the worktree and branch. This script neither
#      polls for the merge nor pulls main nor prunes; the caller sets one timer for the
#      confirmation (the committing skill says how) rather than holding a process open until
#      GitHub is done.
#
#   tools/land-prs.sh <pr-number> [<pr-number>...]
#   tools/land-prs.sh --dry-run <pr-number> [<pr-number>...]
#
# The PRs are handled in the given order, and it stops, naming the PR and the reason, on: a red
# check (the failing checks' names and the PR's URL -- see below for why this is not restricted to
# gh's own `--required` filter), a conflict with main, a PR closed without merging, or a PR that
# edits the old queue. On a red check or a conflict it first turns the PR's auto-merge off and says
# whether GitHub confirmed it, since whatever is pushed to fix the PR is reviewed before it lands.
# A later PR in the list is left untouched when an earlier one stops the run; the PRs before it
# keep the auto-merge they were given.
#
# A PR merges only once it is approved: main's ruleset "main approvals" requires one approving
# review and dismisses stale approvals when new commits are pushed, so a push after the approval
# blocks the merge until a new approval, and an auto-merge left on is safe against a later push.
#
# Why every failing check, not just gh pr checks --required: main's ruleset requires a check
# named exactly "test" (see .github/workflows/ci.yml), which needs both "gates" and "shards" and
# only appears once they are underway -- gh pr checks --required reports nothing before that. Any
# check going red fails "test" too, so looking at every check catches the failure as soon as it
# happens instead of waiting for "test" to summarise it.
#
# This script enables auto-merge and merges pull requests. It never pushes a commit of its own, so
# there is no push path here to give one.
#
# Every GitHub call -- every gh pr view/gh pr checks, git fetch, and every gh pr merge -- mints its
# own fresh token through the caller's own agent identity (tools/lib_agent_role.sh's `agent_run`),
# rather than relying on the one token this script itself may have been wrapped in. Run this
# script itself through `uv run python tools/agent-identity.py run <role> -- tools/land-prs.sh
# ...`, which sets NAPPY_AGENT_ROLE for `agent_run` to read back. Run bare, with NAPPY_AGENT_ROLE
# unset, it calls gh/git directly instead -- exactly what a human running it by hand at their own
# terminal already got.
#
# Bash 3.2-safe, like the rest of tools/ -- see tools/lint.sh's own header.
set -uo pipefail

usage() {
    cat <<'EOF'
usage: tools/land-prs.sh [--help|-h] [--dry-run] <pr-number> [<pr-number>...]

Turns on auto-merge for a queue of already-authorized pull requests, in order, and stops: it does
not wait for them to merge. A PR whose mergeStateStatus already reads CLEAN is merged directly
(gh pr merge <n> --squash), since GitHub refuses to enable auto-merge on a PR that could merge
right now; any other gets auto-merge (gh pr merge <n> --squash --auto), with the direct merge as
the fallback if that still fails with GitHub's "clean status" error. GitHub then merges the PR once
its checks are green and its approval is in; main's ruleset dismisses an approval when a commit is
pushed afterwards, so a later push blocks the merge instead of slipping through.

Before merging a PR it stops on: a conflict with main (resolve it with tools/update-pr.sh), a red
check (the failing checks' names and the PR's URL), a PR closed without merging, and a PR that
edits the old single-file docs/DECISIONS.md, TODO.md or REVIEW.md main has as files (convert it
with tools/convert-queue-edits.py; --dry-run reports it). On a conflict or a red check it turns the
PR's auto-merge off first and says whether GitHub confirmed it, since a fix pushed to the PR is
reviewed (pr-review) before it lands again. Every PR after the one that stopped is left untouched.
A PR that is merely behind main needs nothing, since the ruleset's checks are not strict.

It ends by printing, per PR, what it did and the check that confirms the merge: the PR shows
MERGED, and then tools/prune-merged.sh <branch> retires the worktree and branch. It does not pull
main or prune; set one timer for that check (the committing skill says how) instead of polling.
It also names main's own CI run as the check for two PRs that are wrong together, with the run's
URL when one is cheaply available.

This script enables auto-merge and merges pull requests -- run it only where merging every PR
named on the command line is already authorized, per the committing skill's permission rule.

  --dry-run           Report the plan and each PR's current state, mergeability and check status;
                      touches nothing -- no gh pr merge.

  tools/land-prs.sh 323 324
  tools/land-prs.sh --dry-run 323 324
EOF
}

dry_run=0
prs=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --dry-run) dry_run=1; shift ;;
        -*)
            echo "unknown argument: $1" >&2
            echo >&2
            usage >&2
            exit 2
            ;;
        *)
            if ! [[ "$1" =~ ^[0-9]+$ ]]; then
                echo "not a PR number: $1" >&2
                echo >&2
                usage >&2
                exit 2
            fi
            prs+=("$1")
            shift
            ;;
    esac
done
if [[ ${#prs[@]} -eq 0 ]]; then
    echo "no PR number given" >&2
    echo >&2
    usage >&2
    exit 2
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

# shellcheck source=tools/lib_agent_role.sh
source "$root/tools/lib_agent_role.sh"

refuse() {
    echo "refusing: $*" >&2
    exit 1
}
stop() {
    echo "stopping: $*" >&2
    exit 1
}
# Stops the run on PR $1 with message $2, first turning the PR's auto-merge off. Any change pushed
# to a stopped PR -- a conflict resolved, a red check fixed -- is one its review never saw, and the
# pr-review skill wants it reviewed before it lands; an auto-merge left on would land it unseen.
# Fails closed: unless GitHub confirms auto-merge is off, the message says it could not be.
stop_with_auto_merge_off() {
    local n="$1" msg="$2" off
    agent_run gh pr merge "$n" --disable-auto >/dev/null 2>&1 || true
    if off="$(agent_run gh pr view "$n" --json autoMergeRequest -q '.autoMergeRequest == null' 2>/dev/null)" \
            && [[ "$off" == true ]]; then
        stop "$msg -- auto-merge is off; have any change to it reviewed (pr-review) before landing it again"
    fi
    stop "$msg -- and its auto-merge could NOT be confirmed off: turn it off by hand (gh pr merge $n --disable-auto) before pushing anything to it, or that push merges unreviewed"
}

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git not found" >&2; exit 1; }
command -v gh  >/dev/null 2>&1 || { echo "gh not found" >&2; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "jq not found" >&2; exit 1; }

# shellcheck source=tools/lib_old_queue.sh
source "$root/tools/lib_old_queue.sh"

# The old queue files PR $1 edited that main has as files (tools/lib_old_queue.sh), or nothing.
# Fetches main and the PR's head into a ref of its own, removed again afterwards.
pr_old_queue_edits() {
    local n="$1" ref="refs/land-prs/pr-$1" out=""
    if agent_run git fetch --quiet origin main "+refs/pull/$n/head:$ref" 2>/dev/null; then
        out="$(old_queue_edits "$ref" "refs/remotes/origin/main")"
        git update-ref -d "$ref"
    else
        echo "PR #$n: could not fetch its head to check for old-format queue edits" >&2
        return 1
    fi
    printf '%s' "$out"
}

# ---- PR info as one gh call, decoded with jq ------------------------------------------------
pr_field() { jq -r ".$2" <<<"$1"; }

# Failing or cancelled checks, one "name  link" line per check -- empty when none are red. See
# the header comment for why this is every check rather than gh pr checks --required.
red_checks() {
    local n="$1" checks_json
    checks_json="$(agent_run gh pr checks "$n" --json name,state,bucket,link 2>/dev/null)"
    [[ -z "$checks_json" || "$checks_json" == "null" ]] && return 0
    jq -r '.[] | select(.bucket == "fail" or .bucket == "cancel") | "\(.name)  \(.link)"' <<<"$checks_json"
}

# ================================================================== --dry-run: report only ===
if [[ "$dry_run" -eq 1 ]]; then
    echo "plan: turn on auto-merge for ${#prs[@]} PR(s) in this order: ${prs[*]}"
    for n in "${prs[@]}"; do
        echo
        echo "== PR #$n =="
        if ! pr_json="$(agent_run gh pr view "$n" --json state,mergeable,mergeStateStatus,url,headRefName,title,autoMergeRequest 2>&1)"; then
            echo "  gh pr view $n failed: $pr_json" >&2
            continue
        fi
        echo "  title:      $(pr_field "$pr_json" title)"
        echo "  branch:     $(pr_field "$pr_json" headRefName)"
        echo "  state:      $(pr_field "$pr_json" state)"
        echo "  mergeable:  $(pr_field "$pr_json" mergeable) ($(pr_field "$pr_json" mergeStateStatus))"
        if [[ "$(pr_field "$pr_json" 'autoMergeRequest == null')" == true ]]; then
            echo "  auto-merge: off"
        else
            echo "  auto-merge: on"
        fi
        echo "  url:        $(pr_field "$pr_json" url)"
        if [[ "$(pr_field "$pr_json" mergeStateStatus)" == CLEAN ]]; then
            echo "  would:      merge directly (squash), since it is already clean"
        else
            echo "  would:      turn on auto-merge (squash) and move on"
        fi
        if old="$(pr_old_queue_edits "$n")" && [[ -n "$old" ]]; then
            echo "  queue:      would stop -- $(old_queue_message "PR #$n" "$old")"
        fi
        failing="$(red_checks "$n")"
        if [[ -n "$failing" ]]; then
            echo "  checks:     failing --"
            printf '%s\n' "$failing" | sed 's/^/    /'
        else
            echo "  checks:     none red right now"
        fi
    done
    echo
    echo "dry run: nothing changed -- no gh pr merge, no waiting, no pull, no tools/prune-merged.sh"
    exit 0
fi

# ============================================================================= the real run ===
echo "plan: turn on auto-merge for ${#prs[@]} PR(s) in this order: ${prs[*]}"

# One line per PR for the closing report: "<n> <branch> <what happened>".
report=()

for n in "${prs[@]}"; do
    echo
    echo "== PR #$n =="
    pr_json="$(agent_run gh pr view "$n" --json state,mergeable,mergeStateStatus,url,headRefName 2>&1)" \
        || refuse "gh pr view $n failed: $pr_json"
    state="$(pr_field "$pr_json" state)"
    url="$(pr_field "$pr_json" url)"
    merge_state="$(pr_field "$pr_json" mergeStateStatus)"
    branch="$(pr_field "$pr_json" headRefName)"

    if [[ "$state" == CLOSED ]]; then
        stop "PR #$n ($url) is closed, not open -- nothing to land"
    fi
    if [[ "$state" == MERGED ]]; then
        echo "already merged"
        report+=("$n $branch already merged")
        continue
    fi

    if [[ "$merge_state" == DIRTY || "$(pr_field "$pr_json" mergeable)" == CONFLICTING ]]; then
        stop_with_auto_merge_off "$n" "PR #$n ($url) conflicts with main: resolve it with tools/update-pr.sh $n"
    fi

    old="$(pr_old_queue_edits "$n")" || stop "PR #$n ($url): could not check it for old-format queue edits"
    if [[ -n "$old" ]]; then
        stop_with_auto_merge_off "$n" "$(old_queue_message "PR #$n ($url)" "$old")"
    fi

    # Every check, not only the required ones: see the header for why.
    failing="$(red_checks "$n")"
    if [[ -n "$failing" ]]; then
        stop_with_auto_merge_off "$n" "PR #$n ($url): failing check(s) --
$failing"
    fi

    if [[ "$merge_state" == CLEAN ]]; then
        # Already mergeable right now (checks green, no conflict, approved) -- GitHub's own
        # enablePullRequestAutoMerge refuses a PR in this state ("Pull request is in clean
        # status"), so there is nothing to wait for; merge it directly.
        echo "already clean -- merging directly (squash)"
        merge_out="$(agent_run gh pr merge "$n" --squash 2>&1)" \
            || refuse "PR #$n: gh pr merge --squash failed: $merge_out"
        report+=("$n $branch merged directly")
    else
        echo "turning on auto-merge (squash)"
        if ! merge_out="$(agent_run gh pr merge "$n" --squash --auto 2>&1)"; then
            if [[ "$merge_out" == *"is in clean status"* ]]; then
                echo "auto-merge refused because the PR is already clean -- merging directly (squash)"
                merge_out="$(agent_run gh pr merge "$n" --squash 2>&1)" \
                    || refuse "PR #$n: gh pr merge --squash failed: $merge_out"
                report+=("$n $branch merged directly")
            else
                refuse "PR #$n: gh pr merge --squash --auto failed: $merge_out"
            fi
        else
            report+=("$n $branch auto-merge on")
        fi
    fi
done

echo
echo "done for ${#prs[@]} PR(s): ${prs[*]} -- nothing waits on this run"
for line in "${report[@]}"; do
    n="${line%% *}"
    rest="${line#* }"
    branch="${rest%% *}"
    what="${rest#* }"
    echo "  #$n ($branch): $what"
done
echo
echo "to confirm: each PR shows MERGED (gh pr view <n> --json state), then retire its branch with" \
    "tools/prune-merged.sh <branch> from the main checkout. Set one timer for that check;" \
    "a red check or a conflict found then is fixed, and nothing here polls."
echo
echo "main's own CI run on the last merge is the check that these PRs are not wrong together --" \
    "a semantic conflict between two that touch different files passes each one's own gate and" \
    "only shows up there."
run_url="$(agent_run gh run list --branch main --limit 1 --json url -q '.[0].url' 2>/dev/null)"
if [[ -n "$run_url" ]]; then
    echo "  $run_url"
fi
