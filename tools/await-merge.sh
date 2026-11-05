#!/usr/bin/env bash
# Waits for auto-merged pull requests to merge: sleeps until an estimate of when their CI ends,
# then polls every 20 seconds, and exits when every PR is MERGED or one has to be fixed. It only
# reads GitHub (gh pr view/checks, gh api GET), so it needs no identity and
# .claude/hooks/github-write-guard.sh lets it run bare.
#
#   tools/await-merge.sh <pr-number> [<pr-number>...]
#   tools/await-merge.sh --estimate-only <pr-number>...
#   tools/await-merge.sh --max-poll <minutes> <pr-number>...
#
# Where it fits: tools/land-prs.sh turns auto-merge on and stops; this is the check that the merge
# happened (inbox #1070 in gentle-walrus: a fixed 25-minute timer outlasted the CI, so estimate
# better, undershoot a little, then poll the rest with a script, not an agent). The orchestrating
# session runs it with the Bash tool's run_in_background, which re-invokes the session when it
# exits; no timer and no agent holds the wait.
#
# The estimate (estimate_finish_epoch, one function so it can change in one place): for each
# unfinished job of the PR's latest `ci.yml` run, its start time (now, for a queued one) plus the
# duration the same-named job took in the recent successful `ci.yml` runs on main, the shortest of
# the last three so the estimate undershoots; the latest of those over all jobs, minus one minute.
# A job with no match takes the shortest matched duration; no estimate at all means polling from
# now. A job GitHub has not created yet (a matrix that waits on `plan`) is not counted, which only
# undershoots further. A batch waits for the latest PR's estimate. The numbers (three runs, one
# minute, 20 seconds, 30 minutes) are the filer's proposal, not the player's.
#
# Exits 0 when every PR is MERGED (a PR already merged at the start is reported at once), and
# non-zero, naming the PR and the reason, when one has a red check, a conflict with main, was
# closed unmerged, or the cap ran out. For each merged PR it prints the prune command.
#
# Bash 3.2-safe, like the rest of tools/ -- see tools/lint.sh's own header.
set -uo pipefail

POLL_SECONDS=20
HISTORY_RUNS=3
MARGIN_SECONDS=60
DEFAULT_MAX_POLL_MINUTES=30
WORKFLOW_PATH=".github/workflows/ci.yml"
REPO="JosuaKrause/nappy"

usage() {
    cat <<'EOF'
usage: tools/await-merge.sh [--help|-h] [--estimate-only] [--max-poll <minutes>] <pr-number> [<pr-number>...]

Waits for pull requests whose auto-merge is on (tools/land-prs.sh) to merge. It computes when their
CI should end (for each unfinished job of the PR's latest ci.yml run, its start plus that job's
shortest duration in the last three successful ci.yml runs on main; the latest over all jobs, minus
one minute), sleeps until then, and polls every 20 seconds until every PR is MERGED. A batch waits
for the latest PR's estimate. Only reads GitHub.

Exits 0 when every PR is MERGED, printing the tools/prune-merged.sh command for each; a PR already
merged at the start is reported at once. Exits non-zero, naming the PR and the reason, when a PR
has a red check, a conflict with main, was closed unmerged, or the cap ran out.

  --estimate-only     Print each PR's estimate and the time the wait would end, and exit.
  --max-poll <min>    The cap past the estimate (or past now, with no estimate): default 30.

  tools/await-merge.sh 1069
  tools/await-merge.sh --estimate-only 1069 1070
EOF
}

estimate_only=0
max_poll_minutes="$DEFAULT_MAX_POLL_MINUTES"
prs=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --estimate-only) estimate_only=1; shift ;;
        --max-poll)
            if [[ $# -lt 2 || ! "$2" =~ ^[0-9]+$ ]]; then
                echo "--max-poll needs a whole number of minutes" >&2
                echo >&2
                usage >&2
                exit 2
            fi
            max_poll_minutes="$2"
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

command -v gh >/dev/null 2>&1 || { echo "gh not found" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not found" >&2; exit 1; }

# The shortest duration in seconds of each job name over the last HISTORY_RUNS successful ci.yml
# runs on main, as a JSON object {name: seconds}; {} when none can be read.
history_durations() {
    local runs ids id jobs all="[]"
    runs="$(gh api "repos/$REPO/actions/runs?branch=main&status=success&per_page=20" 2>/dev/null)" || { echo '{}'; return; }
    ids="$(jq -r --arg p "$WORKFLOW_PATH" --argjson n "$HISTORY_RUNS" \
        '[.workflow_runs[] | select(.path == $p)][:$n][] | .id' <<<"$runs")"
    for id in $ids; do
        jobs="$(gh api "repos/$REPO/actions/runs/$id/jobs?per_page=100" 2>/dev/null)" || continue
        all="$(jq -c --argjson j "$jobs" '. + [$j.jobs[]
            | select(.conclusion == "success" and .started_at != null and .completed_at != null)
            | {name, s: ((.completed_at | fromdateiso8601) - (.started_at | fromdateiso8601))}]' <<<"$all")"
    done
    jq -c 'group_by(.name) | map({key: .[0].name, value: (map(.s) | min)}) | from_entries' <<<"$all"
}

# The epoch second PR $1's CI should end, minus the margin; nothing when it cannot be told.
# $2 is the history_durations object, $3 the current epoch.
estimate_finish_epoch() {
    local n="$1" history="$2" now="$3" sha runs run_id jobs
    sha="$(gh pr view "$n" --json headRefOid -q .headRefOid 2>/dev/null)" || return 0
    [[ -n "$sha" ]] || return 0
    runs="$(gh api "repos/$REPO/actions/runs?head_sha=$sha&per_page=30" 2>/dev/null)" || return 0
    run_id="$(jq -r --arg p "$WORKFLOW_PATH" '[.workflow_runs[] | select(.path == $p)][0].id // empty' <<<"$runs")"
    [[ -n "$run_id" ]] || return 0
    jobs="$(gh api "repos/$REPO/actions/runs/$run_id/jobs?per_page=100" 2>/dev/null)" || return 0
    jq -r --argjson h "$history" --argjson now "$now" --argjson margin "$MARGIN_SECONDS" '
        ([$h[]] | min) as $fallback
        | [.jobs[] | select(.status != "completed")
            | ((if .status == "in_progress" and .started_at != null
                then (.started_at | fromdateiso8601) else $now end) as $start
              | ($h[.name] // $fallback) as $dur
              | if $dur == null then empty else $start + $dur end)]
        | if length == 0 then empty else (max - $margin) end' <<<"$jobs"
}

iso() { jq -rn --argjson e "$1" '$e | todate'; }

# Failing or cancelled checks of PR $1, one name per line.
red_checks() {
    gh pr checks "$1" --json name,bucket 2>/dev/null \
        | jq -r '.[]? | select(.bucket == "fail" or .bucket == "cancel") | .name'
}

now="$(date +%s)"
pending=()
branches=()
merged_report=()
history="$(history_durations)"
latest=""
for n in "${prs[@]}"; do
    info="$(gh pr view "$n" --json state,headRefName,url 2>&1)" || { echo "gh pr view $n failed: $info" >&2; exit 1; }
    state="$(jq -r .state <<<"$info")"
    branch="$(jq -r .headRefName <<<"$info")"
    if [[ "$state" == MERGED ]]; then
        echo "PR #$n is already merged: tools/prune-merged.sh $branch"
        merged_report+=("$n")
        continue
    fi
    if [[ "$state" == CLOSED ]]; then
        echo "PR #$n was closed without merging: $(jq -r .url <<<"$info")" >&2
        exit 1
    fi
    est="$(estimate_finish_epoch "$n" "$history" "$now")"
    if [[ -n "$est" ]]; then
        echo "PR #$n: CI should end about $(iso "$((est + MARGIN_SECONDS))"); estimate $(iso "$est")"
        if [[ -z "$latest" || "$est" -gt "$latest" ]]; then latest="$est"; fi
    else
        echo "PR #$n: no estimate; polling from now"
    fi
    pending+=("$n")
    branches+=("$branch")
done

if [[ ${#pending[@]} -eq 0 ]]; then
    echo "every PR is merged"
    exit 0
fi

if [[ -n "$latest" && "$latest" -gt "$now" ]]; then
    wait_until="$latest"
else
    wait_until="$now"
fi
deadline="$((wait_until + max_poll_minutes * 60))"
echo "wait: sleep until $(iso "$wait_until") ($((wait_until - now)) s from now), then poll every ${POLL_SECONDS} s until $(iso "$deadline") at most"
if [[ "$estimate_only" -eq 1 ]]; then
    exit 0
fi

if [[ "$wait_until" -gt "$now" ]]; then
    sleep "$((wait_until - now))"
fi

while true; do
    still=()
    still_branches=()
    i=0
    for n in "${pending[@]}"; do
        branch="${branches[$i]}"
        i=$((i + 1))
        info="$(gh pr view "$n" --json state,mergeable,mergeStateStatus,url 2>/dev/null)" || {
            still+=("$n"); still_branches+=("$branch"); continue
        }
        state="$(jq -r .state <<<"$info")"
        if [[ "$state" == MERGED ]]; then
            echo "PR #$n merged: tools/prune-merged.sh $branch"
            merged_report+=("$n")
            continue
        fi
        if [[ "$state" == CLOSED ]]; then
            echo "PR #$n was closed without merging: $(jq -r .url <<<"$info")" >&2
            exit 1
        fi
        if [[ "$(jq -r .mergeable <<<"$info")" == CONFLICTING || "$(jq -r .mergeStateStatus <<<"$info")" == DIRTY ]]; then
            echo "PR #$n conflicts with main: resolve it with tools/update-pr.sh $n ($(jq -r .url <<<"$info"))" >&2
            exit 1
        fi
        failing="$(red_checks "$n")"
        if [[ -n "$failing" ]]; then
            echo "PR #$n has a red check: $(tr '\n' ' ' <<<"$failing")($(jq -r .url <<<"$info"))" >&2
            exit 1
        fi
        still+=("$n"); still_branches+=("$branch")
    done
    if [[ ${#still[@]} -eq 0 ]]; then
        echo "every PR is merged"
        exit 0
    fi
    pending=("${still[@]}")
    branches=("${still_branches[@]}")
    if [[ "$(date +%s)" -ge "$deadline" ]]; then
        echo "PR #${pending[0]} still not merged after the cap (${max_poll_minutes} min past the estimate); pending: ${pending[*]}" >&2
        exit 1
    fi
    sleep "$POLL_SECONDS"
done
