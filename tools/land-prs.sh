#!/usr/bin/env bash
# The manual sequence that landed a queue of already-authorized pull requests by hand, twice in
# one session -- see docs/TODO.md, one command lands a queue of pull requests in order:
#
#   1. gh pr merge <n> --squash --auto     (turns auto-merge on) -- or, when the PR's own
#      mergeStateStatus already reads CLEAN (checks green, no conflict), gh pr merge <n> --squash
#      directly, since GitHub refuses to enable auto-merge on a PR that could merge right now
#      ("Pull request is in clean status (enablePullRequestAutoMerge)") -- the same direct merge is
#      the fallback if auto-merge is attempted anyway and fails with that error
#   2. poll gh pr view <n> --json state,mergeable until it is MERGED, or until main moved under it
#      and left it CONFLICTING -- the ruleset's checks are not strict
#      (strict_required_status_checks_policy is false), so a PR that is merely behind main needs
#      nothing and merges once its own green run lands
#   3. only when conflicting: tools/update-pr.sh <n> (merges origin/main in, resolves the
#      recurring docs/DECISIONS.md shape, checks, pushes), then keep waiting
#   4. once merged: git pull --ff-only on main in this checkout, then
#      tools/prune-merged.sh <branch> to retire the worktree and branch
#
#   tools/land-prs.sh <pr-number> [<pr-number>...]
#   tools/land-prs.sh --dry-run <pr-number> [<pr-number>...]
#
# Lands the PRs in the given order, one at a time: the next PR is only brought up to date once
# the previous one has actually merged, since each merge moves main and can conflict a PR that
# was clean a moment ago. It stops, naming the PR and the reason, on: a red check (the failing
# checks' names and the PR's URL -- see below for why this is not restricted to gh's own
# `--required` filter), a conflict tools/update-pr.sh cannot resolve, a PR that closes without
# merging, or that PR's own timeout. A later PR in the list is left untouched when an earlier one
# stops the run.
#
# Why every failing check, not just gh pr checks --required: main's ruleset requires a check
# named exactly "test" (see .github/workflows/ci.yml), which needs both "gates" and "shards" and
# only appears once they are underway -- gh pr checks --required reports nothing before that. Any
# check going red fails "test" too, so watching every check catches the failure as soon as it
# happens instead of waiting for "test" to summarise it.
#
# This script enables auto-merge and merges pull requests. It never pushes a commit of its own --
# tools/update-pr.sh and tools/prune-merged.sh each own their own push, HTTPS fallback included --
# so there is no push path here to give one.
#
# Bash 3.2-safe, like the rest of tools/ -- see tools/lint.sh's own header.
set -uo pipefail

usage() {
    cat <<'EOF'
usage: tools/land-prs.sh [--help|-h] [--dry-run] [--timeout <minutes>] <pr-number> [<pr-number>...]

Lands a queue of already-authorized pull requests in order, one at a time: merges each one --
directly (gh pr merge <n> --squash) when its mergeStateStatus already reads CLEAN, since GitHub
refuses to enable auto-merge on a PR that could merge right now, otherwise by enabling auto-merge
(gh pr merge <n> --squash --auto) and falling back to the direct merge if that still fails with
GitHub's "clean status" error -- waits for GitHub to merge it, runs tools/update-pr.sh <n> only
when an earlier merge left it conflicting with main and keeps waiting -- a PR that is merely
behind main needs nothing, since the ruleset's checks are not strict -- then once merged
fast-forwards main in this checkout (git pull --ff-only) and retires the branch with
tools/prune-merged.sh. After the batch, it names main's own CI run on the last merge as the check
for two PRs that are wrong together and prints the run's URL when one is cheaply available.

This script enables auto-merge and merges pull requests -- run it only where merging every PR
named on the command line is already authorized, per the committing skill's permission rule.

  --dry-run           Report the plan and each PR's current state, mergeability and check status;
                      touches nothing -- no gh pr merge, no tools/update-pr.sh, no git pull, no
                      tools/prune-merged.sh.
  --timeout <minutes> How long to wait for one PR to merge before giving up on it (default 90).
                      The clock restarts for each PR in the list.

Stops, naming the PR and the reason, on: a red check (the failing checks' names and the PR's
URL), a conflict tools/update-pr.sh cannot resolve, a PR that closes without merging, or that
PR's own timeout. Every PR after the one that stopped is left untouched.

Refuses to start, before anything but --dry-run touches anything, unless run from the main
checkout on main -- tools/prune-merged.sh needs both. --dry-run is exempt, since it changes
nothing regardless of where or on what branch it runs.

LAND_PRS_POLL_S sets the polling interval in seconds (default 30).

  tools/land-prs.sh 323 324
  tools/land-prs.sh --dry-run 323 324
  tools/land-prs.sh --timeout 30 323
EOF
}

dry_run=0
timeout_min=90
prs=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --dry-run) dry_run=1; shift ;;
        --timeout)
            if [[ $# -lt 2 ]]; then
                echo "--timeout needs a value" >&2
                echo >&2
                usage >&2
                exit 2
            fi
            if ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" -lt 1 ]]; then
                echo "--timeout must be a positive integer number of minutes, got '$2'" >&2
                echo >&2
                usage >&2
                exit 2
            fi
            timeout_min="$2"
            shift 2
            ;;
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

refuse() {
    echo "refusing: $*" >&2
    exit 1
}
stop() {
    echo "stopping: $*" >&2
    exit 1
}

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git not found" >&2; exit 1; }
command -v gh  >/dev/null 2>&1 || { echo "gh not found" >&2; exit 1; }
command -v jq  >/dev/null 2>&1 || { echo "jq not found" >&2; exit 1; }

# Same convention as tools/update-pr.sh's and tools/prune-merged.sh's own worktree_of(): the main
# checkout is always the first entry `git worktree list --porcelain` prints.
main_checkout="$(cd "$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}')" \
    && pwd -P)"
here="$(pwd -P)"
current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

if [[ "$dry_run" -eq 0 ]]; then
    [[ "$here" == "$main_checkout" ]] \
        || refuse "run this from the main checkout ($main_checkout), not $here -- tools/prune-merged.sh needs that"
    [[ "$current_branch" == "main" ]] \
        || refuse "checkout main first (currently on '$current_branch') -- tools/prune-merged.sh needs that"
    [[ -z "$(git status --porcelain)" ]] \
        || refuse "the main checkout has uncommitted changes -- commit or stash them before landing PRs"
fi

# ---- PR info as one gh call, decoded with jq ------------------------------------------------
pr_field() { jq -r ".$2" <<<"$1"; }

# Failing or cancelled checks, one "name  link" line per check -- empty when none are red. See
# the header comment for why this is every check rather than gh pr checks --required.
red_checks() {
    local n="$1" checks_json
    checks_json="$(gh pr checks "$n" --json name,state,bucket,link 2>/dev/null)"
    [[ -z "$checks_json" || "$checks_json" == "null" ]] && return 0
    jq -r '.[] | select(.bucket == "fail" or .bucket == "cancel") | "\(.name)  \(.link)"' <<<"$checks_json"
}

# ================================================================== --dry-run: report only ===
if [[ "$dry_run" -eq 1 ]]; then
    echo "plan: land ${#prs[@]} PR(s) in this order: ${prs[*]}"
    for n in "${prs[@]}"; do
        echo
        echo "== PR #$n =="
        if ! pr_json="$(gh pr view "$n" --json state,mergeable,mergeStateStatus,url,headRefName,title 2>&1)"; then
            echo "  gh pr view $n failed: $pr_json" >&2
            continue
        fi
        echo "  title:      $(pr_field "$pr_json" title)"
        echo "  branch:     $(pr_field "$pr_json" headRefName)"
        echo "  state:      $(pr_field "$pr_json" state)"
        echo "  mergeable:  $(pr_field "$pr_json" mergeable) ($(pr_field "$pr_json" mergeStateStatus))"
        echo "  url:        $(pr_field "$pr_json" url)"
        failing="$(red_checks "$n")"
        if [[ -n "$failing" ]]; then
            echo "  checks:     failing --"
            printf '%s\n' "$failing" | sed 's/^/    /'
        else
            echo "  checks:     none red right now"
        fi
    done
    echo
    echo "dry run: nothing changed -- no gh pr merge, no tools/update-pr.sh, no git pull, no tools/prune-merged.sh"
    if [[ "$here" != "$main_checkout" || "$current_branch" != "main" ]]; then
        echo "note: a real run would refuse here -- this is $here on '$current_branch', not the main checkout ($main_checkout) on main"
    fi
    exit 0
fi

# ============================================================================= the real run ===
poll_s="${LAND_PRS_POLL_S:-30}"

echo "plan: land ${#prs[@]} PR(s) in this order: ${prs[*]}"

for n in "${prs[@]}"; do
    echo
    echo "== PR #$n =="
    pr_json="$(gh pr view "$n" --json state,mergeable,mergeStateStatus,url,headRefName 2>&1)" \
        || refuse "gh pr view $n failed: $pr_json"
    state="$(pr_field "$pr_json" state)"
    url="$(pr_field "$pr_json" url)"
    merge_state="$(pr_field "$pr_json" mergeStateStatus)"

    if [[ "$state" == CLOSED ]]; then
        stop "PR #$n ($url) is closed, not open -- nothing to land"
    fi

    if [[ "$state" != MERGED ]]; then
        if [[ "$merge_state" == CLEAN ]]; then
            # Already mergeable right now (checks green, no conflict) -- GitHub's own
            # enablePullRequestAutoMerge refuses a PR in this state ("Pull request is in clean
            # status"), so there is nothing to wait for; merge it directly.
            echo "already clean -- merging directly (squash)"
            merge_out="$(gh pr merge "$n" --squash 2>&1)" \
                || refuse "PR #$n: gh pr merge --squash failed: $merge_out"
        else
            echo "enabling auto-merge (squash)"
            if ! merge_out="$(gh pr merge "$n" --squash --auto 2>&1)"; then
                if [[ "$merge_out" == *"is in clean status"* ]]; then
                    echo "auto-merge refused because the PR is already clean -- merging directly (squash)"
                    merge_out="$(gh pr merge "$n" --squash 2>&1)" \
                        || refuse "PR #$n: gh pr merge --squash failed: $merge_out"
                else
                    refuse "PR #$n: gh pr merge --squash --auto failed: $merge_out"
                fi
            fi
        fi
    fi

    deadline=$(( $(date +%s) + timeout_min * 60 ))
    while true; do
        now="$(date +%s)"
        if [[ "$now" -gt "$deadline" ]]; then
            stop "PR #$n: timed out after ${timeout_min}m waiting for it to merge"
        fi

        pr_json="$(gh pr view "$n" --json state,mergeable,url 2>&1)" \
            || refuse "PR #$n: gh pr view failed: $pr_json"
        state="$(pr_field "$pr_json" state)"
        mergeable="$(pr_field "$pr_json" mergeable)"
        url="$(pr_field "$pr_json" url)"

        [[ "$state" == MERGED ]] && { echo "PR #$n merged"; break; }
        [[ "$state" == CLOSED ]] && stop "PR #$n ($url) closed without merging"

        failing="$(red_checks "$n")"
        if [[ -n "$failing" ]]; then
            stop "PR #$n ($url): failing check(s) --
$failing"
        fi

        # The ruleset's checks are not strict (strict_required_status_checks_policy is false), so
        # a PR that is merely behind main merges on its own once its own run is green -- nothing
        # to do here. Only a real conflict with main needs tools/update-pr.sh to bring it up to
        # date; that re-run is on this branch alone and proves nothing about a PR merged beside it,
        # which is why main's own CI run after the batch is the check that matters there.
        if [[ "$mergeable" == CONFLICTING ]]; then
            echo "PR #$n conflicts with main; running tools/update-pr.sh $n"
            if ! ./tools/update-pr.sh "$n"; then
                stop "PR #$n ($url): tools/update-pr.sh could not bring it up to date -- see its output above"
            fi
            echo "up to date with main; still waiting for PR #$n to merge"
            continue
        fi

        sleep "$poll_s"
    done

    echo "fast-forwarding main"
    git pull --ff-only origin main \
        || refuse "git pull --ff-only failed after PR #$n merged -- resolve main by hand before continuing"

    branch="$(gh pr view "$n" --json headRefName -q .headRefName 2>/dev/null)"
    if [[ -n "$branch" ]]; then
        if ! ./tools/prune-merged.sh "$branch"; then
            echo "warning: tools/prune-merged.sh $branch reported a problem (see output above) -- PR #$n is merged; cleanup is incomplete, continuing to the next PR" >&2
        fi
    fi
done

echo
echo "landed ${#prs[@]} PR(s): ${prs[*]}"
echo
echo "main's own CI run on the last merge is the check that these PRs are not wrong together --" \
    "a semantic conflict between two that touch different files passes each one's own gate and" \
    "only shows up there. Watch it."
run_url="$(gh run list --branch main --limit 1 --json url -q '.[0].url' 2>/dev/null)"
[[ -n "$run_url" ]] && echo "  $run_url"
