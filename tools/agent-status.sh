#!/usr/bin/env bash
# Survey every agent worktree: what is on disk, how it stands with its own remote, its pull
# request's CI state, its brief, and whether its transcript is still warm enough to resume.
# Also warns when the worktree kept changing well after its credited agent's transcript did --
# the sign of a replacement started into it without its `agent:` line being updated (see the
# orchestrating skill's "An agent that died mid-task is replaced in its own worktree").
# Read-only apart from a `git fetch` — see the orchestrating skill's "Recovering from an
# interruption", whose first step this script is.
#
#   tools/agent-status.sh              # fetch, then one block per worktree
#   tools/agent-status.sh --no-fetch   # skip the fetch; ahead/behind uses what is already known
#
# The main checkout (always the first entry in `git worktree list`, same convention
# tools/prune-merged.sh uses) is never one of the blocks -- there is no agent in it to report on.
#
# AGENT_STATUS_BRIEFS overrides the briefs directory (default: the main checkout's
# `.claude/briefs`) -- for exercising the stale-ownership warning against a throwaway brief
# without writing into a worktree-isolated agent's own checkout.
set -uo pipefail

usage() {
    cat <<'EOF'
usage: tools/agent-status.sh [--help|-h] [--no-fetch]

Prints one block per agent worktree (every entry in `git worktree list` except the main
checkout): its path, branch and uncommitted file count; how far it is ahead/behind its own
upstream; its pull request's number, state, draft flag and CI rollup; its brief file if one
exists; its agent id with the age of its transcript and a warm/cold verdict; and a warning if
the worktree changed well after that agent's last transcript write.

--no-fetch skips the `git fetch` and reports ahead/behind against whatever was last fetched.

AGENT_STATUS_BRIEFS=<dir> reads brief files from <dir> instead of the main checkout's
`.claude/briefs` (env var, not a flag).

  tools/agent-status.sh
  tools/agent-status.sh --no-fetch
EOF
}

do_fetch=1
for arg in "$@"; do
    case "$arg" in
        -h|--help)   usage; exit 0 ;;
        --no-fetch)  do_fetch=0 ;;
        *)           echo "unknown argument: $arg" >&2; echo >&2; usage >&2; exit 2 ;;
    esac
done

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 1; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

# Claude Code's own prompt cache lasts 60 minutes from an agent's last request; the orchestrating
# skill resumes only with 5 minutes to spare ("Resume only with five minutes to spare"), so 55 is
# the last minute a transcript still counts as warm here.
WARM_MINUTES=55

# A live agent's own commit can land a few minutes after its transcript's last write -- the
# request that triggers the write and the `git commit` that follows it are not the same instant.
# Only drift past this margin is worth a warning.
STALE_MARGIN_MINUTES=5

mtime_of() {
    case "$(uname -s)" in
        Darwin) stat -f %m "$1" ;;
        *)      stat -c %Y "$1" ;;
    esac
}

if [[ "$do_fetch" -eq 1 ]]; then
    git fetch --quiet || echo "warning: git fetch failed; ahead/behind may be stale" >&2
fi

# `git worktree list --porcelain` always names the main checkout first (tools/prune-merged.sh
# relies on the same fact).
main_checkout="$(cd "$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}')" \
    && pwd -P)"

# Briefs live in the main checkout, except when AGENT_STATUS_BRIEFS names a stand-in -- see the
# header comment.
briefs_dir="${AGENT_STATUS_BRIEFS:-$main_checkout/.claude/briefs}"

# One "path<TAB>branch" line per worktree, main checkout first, "(detached)" for a worktree with
# no branch checked out.
worktrees=()
while IFS= read -r line; do
    [[ -n "$line" ]] && worktrees+=("$line")
done < <(git worktree list --porcelain | awk '
    /^worktree / { if (path != "") print path "\t" branch; path = substr($0, 10); branch = "(detached)" }
    /^branch /   { b = substr($0, 8); sub("^refs/heads/", "", b); branch = b }
    END          { if (path != "") print path "\t" branch }
')

# Every session's transcript directory for this checkout: ~/.claude/projects/<slug>, where <slug>
# is the main checkout's absolute path with every "/" turned into "-". Derived, never hard-coded,
# so this still works from anybody else's home directory.
slug="${main_checkout//\//-}"
projects_dir="$HOME/.claude/projects/$slug"

# The agent-<id>.meta.json next to a transcript carries "worktreePath" only for a worktree-isolated
# spawn; a replacement agent started without isolation has none. $1 is the worktree's own realpath.
agent_id_from_meta() {
    local wt="$1" best_id="" best_mtime=-1
    [[ -d "$projects_dir" ]] || return 0
    local meta
    while IFS= read -r meta; do
        local mp
        mp="$(jq -r '.worktreePath // empty' "$meta" 2>/dev/null)"
        [[ -z "$mp" ]] && continue
        local mp_real
        mp_real="$(cd "$mp" 2>/dev/null && pwd -P)"
        [[ "$mp_real" == "$wt" ]] || continue
        local m
        m="$(mtime_of "$meta")"
        if [[ "$m" -gt "$best_mtime" ]]; then
            best_mtime="$m"
            best_id="$(basename "$meta")"
            best_id="${best_id#agent-}"
            best_id="${best_id%.meta.json}"
        fi
    done < <(find "$projects_dir" -mindepth 3 -maxdepth 3 -type f -name 'agent-*.meta.json' -path '*/subagents/*' 2>/dev/null)
    printf '%s' "$best_id"
}

transcript_for_id() {
    local id="$1"
    [[ -z "$id" || ! -d "$projects_dir" ]] && return 0
    find "$projects_dir" -mindepth 3 -maxdepth 3 -type f -name "agent-$id.jsonl" -path '*/subagents/*' 2>/dev/null | head -1
}

# The newest of HEAD's committer time and the mtimes of its uncommitted files (deleted paths
# skipped -- they have none to read) -- the last moment anything in the worktree changed, a
# commit or an edit alike. $1 is the worktree's own path.
worktree_activity_epoch() {
    local wt="$1" newest ct line status_code rest fpath fmtime
    ct="$(git -C "$wt" log -1 --format=%ct 2>/dev/null)"
    newest="${ct:-0}"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        status_code="${line:0:2}"
        rest="${line:3}"
        case "$rest" in
            *" -> "*) rest="${rest#*" -> "}" ;;
        esac
        case "$status_code" in
            *D*) continue ;;
        esac
        fpath="$wt/$rest"
        [[ -e "$fpath" ]] || continue
        fmtime="$(mtime_of "$fpath" 2>/dev/null)" || continue
        [[ -n "$fmtime" && "$fmtime" -gt "$newest" ]] && newest="$fmtime"
    done < <(git -C "$wt" status --porcelain 2>/dev/null)
    printf '%s' "$newest"
}

# gh's own jq engine rolls a PR's checks up to one word: "fail" if any check completed anything
# but a success-shaped conclusion, "pending" if any has not completed, "no checks" if the array
# is empty, "pass" otherwise. Handles both current check runs (status/conclusion) and legacy
# commit statuses (state) -- gh's statusCheckRollup can return either shape per entry.
PR_JQ='
def rollup:
  if (.statusCheckRollup | length) == 0 then "no checks"
  else
    ( .statusCheckRollup | map(
        if has("conclusion") then
          if .status != "COMPLETED" then "pending"
          elif (.conclusion == "SUCCESS" or .conclusion == "NEUTRAL" or .conclusion == "SKIPPED") then "pass"
          else "fail"
          end
        else
          if .state == "SUCCESS" then "pass"
          elif .state == "PENDING" or .state == "EXPECTED" then "pending"
          else "fail"
          end
        end
      ) ) as $r
    | if ($r | any(. == "fail")) then "fail"
      elif ($r | any(. == "pending")) then "pending"
      else "pass"
      end
  end;
[ (.number|tostring), .state, (.isDraft|tostring), rollup ] | @tsv
'

first=1
for entry in "${worktrees[@]}"; do
    path="${entry%%$'\t'*}"
    branch="${entry#*$'\t'}"
    [[ "$(cd "$path" 2>/dev/null && pwd -P)" == "$main_checkout" ]] && continue

    [[ "$first" -eq 1 ]] && first=0 || echo
    echo "== $path =="
    echo "branch:      $branch"

    uncommitted="$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
    echo "uncommitted: $uncommitted file(s)"

    if git -C "$path" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
        read -r behind ahead < <(git -C "$path" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
        echo "upstream:    ${ahead:-0} ahead, ${behind:-0} behind"
    else
        echo "upstream:    no upstream"
    fi

    if [[ "$branch" == "(detached)" ]]; then
        echo "PR:          no PR"
    elif pr_json="$(gh pr view "$branch" --json number,state,isDraft,statusCheckRollup 2>/dev/null)"; then
        IFS=$'\t' read -r pr_number pr_state pr_draft pr_ci < <(printf '%s' "$pr_json" | jq -r "$PR_JQ")
        draft_note=""
        [[ "$pr_draft" == "true" ]] && draft_note=", draft"
        echo "PR:          #$pr_number $pr_state$draft_note — CI $pr_ci"
    else
        echo "PR:          no PR"
    fi

    slug_branch="${branch//\//-}"
    brief_file="$briefs_dir/$slug_branch.md"
    if [[ -f "$brief_file" ]]; then
        echo "brief:       $brief_file"
    else
        echo "brief:       none"
    fi

    wt_real="$(cd "$path" 2>/dev/null && pwd -P)"
    agent_id=""
    if [[ -f "$brief_file" ]]; then
        agent_id="$(awk -F': ' '/^agent: /{id=$2} END{print id}' "$brief_file")"
    fi
    [[ -z "$agent_id" ]] && agent_id="$(agent_id_from_meta "$wt_real")"

    transcript=""
    [[ -n "$agent_id" ]] && transcript="$(transcript_for_id "$agent_id")"

    now="$(date +%s)"
    if [[ -z "$transcript" ]]; then
        echo "agent:       transcript not found"
    else
        mtime="$(mtime_of "$transcript")"
        age_min=$(( (now - mtime) / 60 ))
        if [[ "$age_min" -lt "$WARM_MINUTES" ]]; then
            verdict="warm"
        else
            verdict="cold"
        fi
        echo "agent:       $agent_id — last write ${age_min}m ago — $verdict"
    fi

    # Stale ownership: the worktree kept changing well after the credited agent's transcript did
    # (or nobody is credited at all while it keeps changing) -- the shape a replacement started
    # into this worktree without its `agent:` line being appended leaves behind.
    activity_epoch="$(worktree_activity_epoch "$path")"
    if [[ -n "$transcript" ]]; then
        drift_min=$(( (activity_epoch - mtime) / 60 ))
        if [[ "$drift_min" -gt "$STALE_MARGIN_MINUTES" ]]; then
            echo "warning:     worktree changed ${drift_min}m after $agent_id's last write — another agent working here? append its agent: line to the brief"
        fi
    elif [[ -z "$agent_id" ]]; then
        recent_min=$(( (now - activity_epoch) / 60 ))
        if [[ "$recent_min" -ge 0 && "$recent_min" -le "$WARM_MINUTES" ]]; then
            echo "warning:     worktree changed ${recent_min}m ago with no credited agent — someone working here? append its agent: line to the brief"
        fi
    fi
done

[[ "$first" -eq 1 ]] && echo "no agent worktrees"
exit 0
