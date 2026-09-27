#!/usr/bin/env bash
# Survey every agent worktree, in this checkout and in every other local clone of the same repo:
# what is on disk, how it stands with its own remote, its pull request's CI state, its brief, and
# whether its credited agent is still warm enough to resume. Each clone's own evidence decides
# how it is credited and labelled -- a Claude Code transcripts directory for it, a Codex session
# naming it, or both -- never which clone the script happens to run from, so the same survey
# reads the same way run from any clone (see "Codex" below for how a Codex session is found and
# read, and projects_dir_for below for a clone's own transcripts directory). Also warns when a
# worktree kept changing well after its credited agent's transcript did -- the sign
# of a replacement started into it without its `agent:` line being updated (see the orchestrating
# skill's "An agent that died mid-task is replaced in its own worktree") -- and when the same
# branch is checked out in more than one clone, since that is two hosts possibly working one PR.
# Read-only apart from a `git fetch` in each clone surveyed -- see the orchestrating skill's
# "Recovering from an interruption", whose first step this script is.
#
#   tools/agent-status.sh              # fetch, then one block per worktree
#   tools/agent-status.sh --no-fetch   # skip the fetch; ahead/behind uses what is already known
#
# The main checkout (always the first entry in `git worktree list`, same convention
# tools/prune-merged.sh uses) is never one of its own clone's blocks -- there is no agent in it to
# report on. Another clone's own checkout is skipped the same way.
#
# AGENT_STATUS_BRIEFS overrides the briefs directory (default: the main checkout's
# `.claude/briefs`) -- for exercising the stale-ownership warning against a throwaway brief
# without writing into a worktree-isolated agent's own checkout. Applies only to this checkout;
# another clone's briefs always come from its own `.claude/briefs`.
#
# AGENT_STATUS_CLONES names other local clones of this repo to survey too, colon-separated (like
# $PATH) -- nothing is assumed about where they live. A clone whose worktrees Codex's own session
# history already names as a `cwd` (see "Codex" below) is found the same way without being listed.
# A clone that does not exist, is not a git repository, or does not share this repo's `origin` is
# skipped with a warning on stderr; the auto-discovered kind is skipped silently, since it is only
# a guess. Neither environment variable needs exporting every session -- see "the .env fallback".
#
# CODEX_HOME overrides where Codex's own session history is read from (default `~/.codex`,
# Codex's own documented variable) -- read only when the directory it names exists, so a machine
# without Codex sees exactly today's output.
#
# The .env fallback: AGENT_STATUS_CLONES and CODEX_HOME are also read from a `.env` file --
# `KEY=value` per line, blank lines and `#` comments ignored, one optional layer of surrounding
# quotes stripped -- the same convention `tools/goatcounter.py`'s `env_or_dotenv` documents. The
# process environment always wins; when a variable is not set there, this checkout's own `.env` is
# read, then -- if this is a linked worktree -- the main checkout's `.env` after it. Nothing here
# prints either value, and nothing here writes a `.env` file: put a line such as
# `AGENT_STATUS_CLONES=/path/to/other/clone` in one at the repository root to keep a value across
# sessions without exporting it.
set -uo pipefail

usage() {
    cat <<'EOF'
usage: tools/agent-status.sh [--help|-h] [--no-fetch]

Prints one block per agent worktree, across this checkout and every other local clone of the same
repo (see AGENT_STATUS_CLONES and CODEX_HOME below): its clone and host label (from that clone's
own evidence -- a Claude Code transcripts directory, a Codex session naming it, or both -- never
from which clone is running the script), path, branch and uncommitted file count; how far it is
ahead/behind its own upstream; its pull request's number, state, draft flag and CI rollup; its
brief file if one exists; its credited agent -- that clone's own Claude Code transcript if one
matches this worktree, else a Codex session -- with the agent's id or nickname, its age and a
warm/cold verdict (Codex also gets "active"); a warning if the worktree changed well after that
agent's last transcript write; and a warning if the same branch is checked out in more than one
clone.

--no-fetch skips the `git fetch` in every clone surveyed and reports ahead/behind against
whatever was last fetched.

AGENT_STATUS_CLONES=<clone>[:<clone>...] surveys these other local clones of this repo too
(colon-separated, like $PATH); each must exist, be a git repository, and share this repo's
`origin`, or it is skipped with a warning. Codex's own worktrees are found without this, from its
session history's own `cwd` values (see CODEX_HOME) -- list a clone here only for one Codex has
not yet worked in, or that is not Codex's.

CODEX_HOME=<dir> reads Codex's session history from <dir>/sessions instead of the default
~/.codex/sessions -- Codex's own documented variable. Read only when that directory exists.

AGENT_STATUS_CLONES and CODEX_HOME are also read from a `.env` file (repo root, then -- in a
linked worktree -- the main checkout) when not set in the process environment; see the header
comment for the exact convention. Nothing here creates or edits a `.env` file.

AGENT_STATUS_BRIEFS=<dir> reads this checkout's own brief files from <dir> instead of the main
checkout's `.claude/briefs` (env var, not a flag) -- applies only to this checkout, never to
another clone.

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

# Codex's own prompt cache lasts 20 minutes, with the same 5-minute resume margin ("Claude Code's
# cache lasts one hour, Codex's twenty minutes" / "Resume only with five minutes to spare -- 55
# minutes in Claude Code, 15 in Codex", orchestrating skill), so 15 is the last minute a Codex
# session still counts as warm.
CODEX_WARM_MINUTES=15

# Under this many minutes since its last write, a Codex session is very likely still mid-turn --
# long enough to rule out clock skew between writes, short enough that a finished turn would have
# gone quiet. Not a documented Codex number, just this script's own reading of "active".
CODEX_ACTIVE_MINUTES=2

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

# `git worktree list --porcelain` always names the main checkout first (tools/prune-merged.sh
# relies on the same fact), for any clone -- $1.
main_checkout_of() {
    (cd "$(git -C "$1" worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}')" \
        && pwd -P)
}

main_checkout="$(main_checkout_of "$root")"

# ------------------------------------------------------------------------- the .env fallback ---
# `KEY=value` per line, blank lines and `#` comments ignored, one optional layer of surrounding
# quotes stripped -- never sourced as shell code. Mirrors tools/goatcounter.py's
# `env_or_dotenv`/`_parse_dotenv` (see the header comment) in shell, since that convention is
# Python and this script is not; a change to one convention is a change to both.
dotenv_get() {
    local file="$1" key="$2" line stripped k v result found=1 vlen vfirst vlast
    [[ -f "$file" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        stripped="${line#"${line%%[![:space:]]*}"}"
        stripped="${stripped%"${stripped##*[![:space:]]}"}"
        [[ -z "$stripped" || "$stripped" == \#* || "$stripped" != *=* ]] && continue
        k="${stripped%%=*}"
        v="${stripped#*=}"
        k="${k%"${k##*[![:space:]]}"}"; k="${k#"${k%%[![:space:]]*}"}"
        [[ -z "$k" ]] && continue
        v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
        if [[ "$k" == "$key" ]]; then
            # Bash-3.2-safe quote stripping (no negative offsets/lengths in substring expansion,
            # which need bash 4.2+ -- macOS ships 3.2 as its system /bin/bash).
            vlen=${#v}
            if [[ "$vlen" -ge 2 ]]; then
                vfirst="${v:0:1}"; vlast="${v:$((vlen-1)):1}"
                if [[ "$vfirst" == "$vlast" && ( "$vfirst" == "'" || "$vfirst" == '"' ) ]]; then
                    v="${v:1:$((vlen-2))}"
                fi
            fi
            result="$v"; found=0
        fi
    done < "$file"
    [[ "$found" -eq 0 ]] || return 1
    printf '%s' "$result"
}

# `key` from the process environment, else this checkout's own `.env`, else -- in a linked
# worktree -- the main checkout's `.env`. The process environment always wins.
env_or_dotenv() {
    local key="$1" value
    value="${!key:-}"
    [[ -n "$value" ]] && { printf '%s' "$value"; return 0; }
    value="$(dotenv_get "$root/.env" "$key" 2>/dev/null)" && [[ -n "$value" ]] && { printf '%s' "$value"; return 0; }
    if [[ "$root" != "$main_checkout" ]]; then
        value="$(dotenv_get "$main_checkout/.env" "$key" 2>/dev/null)" && [[ -n "$value" ]] && { printf '%s' "$value"; return 0; }
    fi
    return 1
}

# ------------------------------------------------------------------------------------- Codex ---
# Everything that reads Codex's own session format lives in this section, so a format change is
# one place to fix -- not one literal function, since the two jobs the rest of the script needs
# (credit a worktree's most recent worker, `codex_credit_for`; list the worktrees Codex has ever
# named, `codex_hit_worktrees`) share the same raw hits but return different shapes, and folding
# both into one function would mean a caller passing a flag to say which it wants. Those two are
# this section's only entry points; `codex_files_for` and `codex_pick_worker_file` are private
# steps only `codex_credit_for` calls. Codex sessions are JSONL files under $CODEX_HOME/sessions/YYYY/MM/DD/
# rollout-*.jsonl; of the two other places Codex keeps session records (~/.codex/session_index.jsonl
# and state_5.sqlite), neither names a sub-agent's actual worktree -- session_index.jsonl carries
# only an id, a thread name and a timestamp, and while state_5.sqlite's own `threads` table has a
# `cwd` column, it is the same clone-root value the rollout's own `session_meta` line carries, not
# the worktree a sub-agent later `cd`s into (see below) -- so the rollout files are the only source
# that can answer this and are what this reads.
#
# Line 1 of a rollout file is `{"type":"session_meta","payload":{"cwd":...,"source":...}}`. A
# sub-agent's `source` is `{"subagent":{"thread_spawn":{"agent_nickname":...}}}`;
# `{"subagent":{"other":"guardian"}}` is Codex's own approval guardian, never a worker, and is
# skipped. Empirically (across every session on this machine, at the time this was written), a
# sub-agent's own `session_meta` and `turn_context` lines still carry its *parent's* cwd -- the
# clone root -- even while it works inside a worktree; only a shell command it actually ran
# carries the true cwd, as `"cwd":"file://<abs path>"` on that command's own event line. That is
# the only reliable evidence of which worktree a Codex session worked in, and is also how another
# clone of this repo is found without being told about it: strip a matched worktree path's own
# `/.claude/worktrees/<name>` suffix to get its clone root.
codex_home="$(env_or_dotenv CODEX_HOME)"; codex_home="${codex_home:-$HOME/.codex}"
codex_sessions_dir="$codex_home/sessions"

# "worktree path<TAB>rollout file" lines, one per hit -- a plain string rather than an associative
# array, since this repo's own /bin/bash is 3.2 (macOS's system shell, which predates them).
# codex_files_for() below is the lookup; codex_hit_worktrees() derives the distinct worktree
# paths seen, for the clone-discovery pass just below.
codex_hits_tsv=""
if [[ -d "$codex_sessions_dir" ]] && command -v rg >/dev/null 2>&1; then
    codex_hits_tsv="$(rg -n --no-heading -o '"cwd":"file://[^"]*/\.claude/worktrees/[^/"]*' "$codex_sessions_dir" 2>/dev/null | \
        awk -F: '{
            file = $1
            rest = $0
            sub(/^[^:]*:[0-9]+:/, "", rest)
            idx = index(rest, "file://")
            if (idx == 0) next
            wt = substr(rest, idx + 7)
            print wt "\t" file
        }')"
fi

# Every rollout file whose own commands' cwd named worktree $1, one per line.
codex_files_for() {
    [[ -z "$codex_hits_tsv" ]] && return 0
    printf '%s\n' "$codex_hits_tsv" | awk -F'\t' -v k="$1" '$1 == k { print $2 }'
}

# Every distinct worktree path any Codex session's commands named, one per line.
codex_hit_worktrees() {
    [[ -z "$codex_hits_tsv" ]] && return 0
    printf '%s\n' "$codex_hits_tsv" | awk -F'\t' '{ print $1 }' | sort -u
}

# The newest file among a newline-separated list of candidates ($1) that is not Codex's own
# approval guardian (never a worker), as "mtime<TAB>file" -- the guardian check
# (`source.subagent.other == "guardian"` on the file's own session_meta line) is inline since
# nothing else needs it.
codex_pick_worker_file() {
    { while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        m="$(mtime_of "$f" 2>/dev/null)" || continue
        printf '%s\t%s\n' "$m" "$f"
    done <<<"$1"; } | sort -t $'\t' -k1,1 -rn | { while IFS=$'\t' read -r m f; do
        guardian="$(head -1 "$f" 2>/dev/null | jq -r 'try .payload.source.subagent.other catch empty' 2>/dev/null)"
        [[ "$guardian" == "guardian" ]] && continue
        printf '%s\t%s\n' "$m" "$f"
        break
    done; }
}

# The most recent Codex worker session credited to worktree $1 (its own realpath), branch $2, as
# "nickname<TAB>mtime<TAB>note" (note empty unless found only by the looser branch-name fallback);
# prints nothing if none is found.
codex_credit_for() {
    local wt="$1" branch="$2" candidates note=""
    candidates="$(codex_files_for "$wt")"
    if [[ -z "$candidates" && -n "$branch" && "$branch" != "(detached)" \
          && -d "$codex_sessions_dir" ]] && command -v rg >/dev/null 2>&1; then
        candidates="$(rg -l --fixed-strings "$branch" "$codex_sessions_dir" 2>/dev/null | while IFS= read -r f; do
            rg -q --fixed-strings '"CommandExecution"' "$f" 2>/dev/null && printf '%s\n' "$f"
        done)"
        note="matched by branch name, not by worktree"
    fi
    [[ -z "$candidates" ]] && return 0
    local picked c_mtime c_file
    picked="$(codex_pick_worker_file "$candidates")"
    [[ -z "$picked" ]] && return 0
    IFS=$'\t' read -r c_mtime c_file <<<"$picked"
    local nickname
    nickname="$(head -1 "$c_file" 2>/dev/null | jq -r 'try .payload.source.subagent.thread_spawn.agent_nickname catch empty' 2>/dev/null)"
    [[ -z "$nickname" ]] && nickname="codex"
    printf '%s\t%s\t%s' "$nickname" "$c_mtime" "$note"
}

# ------------------------------------------------------------------------------- other clones ---
own_origin="$(git -C "$main_checkout" remote get-url origin 2>/dev/null || true)"
other_clones=()

# Whether $1 is already the main checkout or already in other_clones -- a plain linear scan over a
# handful of clones, rather than an associative array (this repo's own /bin/bash is 3.2, which
# predates them).
clone_known() {
    local c="$1" x
    [[ "$c" == "$main_checkout" ]] && return 0
    if [[ "${#other_clones[@]}" -gt 0 ]]; then
        for x in "${other_clones[@]}"; do
            [[ "$x" == "$c" ]] && return 0
        done
    fi
    return 1
}

add_clone_candidate() {
    local c="$1" explicit="$2" c_real c_origin
    [[ -z "$c" ]] && return 0
    if [[ ! -d "$c" ]]; then
        [[ "$explicit" -eq 1 ]] && echo "warning: AGENT_STATUS_CLONES entry '$c' does not exist; skipped" >&2
        return 0
    fi
    if ! git -C "$c" rev-parse --git-dir >/dev/null 2>&1; then
        [[ "$explicit" -eq 1 ]] && echo "warning: AGENT_STATUS_CLONES entry '$c' is not a git repository; skipped" >&2
        return 0
    fi
    c_real="$(main_checkout_of "$c")"
    clone_known "$c_real" && return 0
    c_origin="$(git -C "$c_real" remote get-url origin 2>/dev/null || true)"
    if [[ -z "$own_origin" || "$c_origin" != "$own_origin" ]]; then
        [[ "$explicit" -eq 1 ]] && echo "warning: AGENT_STATUS_CLONES entry '$c' does not share this repo's origin; skipped" >&2
        return 0
    fi
    other_clones+=("$c_real")
}

explicit_clones="$(env_or_dotenv AGENT_STATUS_CLONES || true)"
if [[ -n "$explicit_clones" ]]; then
    IFS=':' read -ra _explicit_list <<<"$explicit_clones"
    for c in "${_explicit_list[@]}"; do add_clone_candidate "$c" 1; done
fi
while IFS= read -r wtpath; do
    [[ -z "$wtpath" ]] && continue
    add_clone_candidate "${wtpath%/.claude/worktrees/*}" 0
done < <(codex_hit_worktrees)

if [[ "$do_fetch" -eq 1 ]]; then
    git -C "$main_checkout" fetch --quiet || echo "warning: git fetch failed in $main_checkout; ahead/behind may be stale" >&2
    if [[ "${#other_clones[@]}" -gt 0 ]]; then
        for clone in "${other_clones[@]}"; do
            git -C "$clone" fetch --quiet || echo "warning: git fetch failed in $clone; ahead/behind may be stale" >&2
        done
    fi
fi

# Briefs live in a clone's own `.claude/briefs`, except this checkout's own, where
# AGENT_STATUS_BRIEFS names a stand-in -- see the header comment.
briefs_dir_for() {
    if [[ "$1" == "$main_checkout" ]]; then
        printf '%s' "${AGENT_STATUS_BRIEFS:-$1/.claude/briefs}"
    else
        printf '%s' "$1/.claude/briefs"
    fi
}

# One "path<TAB>branch" line per worktree of clone $1, main checkout first, "(detached)" for a
# worktree with no branch checked out.
worktrees_for_clone() {
    git -C "$1" worktree list --porcelain | awk '
        /^worktree / { if (path != "") print path "\t" branch; path = substr($0, 10); branch = "(detached)" }
        /^branch /   { b = substr($0, 8); sub("^refs/heads/", "", b); branch = b }
        END          { if (path != "") print path "\t" branch }
    '
}

# Every clone's own transcript directory is ~/.claude/projects/<slug>, where <slug> is that
# clone's own absolute path with every "/" turned into "-" -- a clone's own, never the running
# checkout's, so a clone this script is not currently running from still gets its own worktrees'
# transcripts (a bug found in review of #393: labelling and crediting used to key off
# `$main_checkout`, the checkout the script happened to run from, so running it from the Codex
# clone flipped every label and dropped every Claude credit).
projects_dir_for() {
    local slug="${1//\//-}"
    printf '%s' "$HOME/.claude/projects/$slug"
}

# The agent-<id>.meta.json next to a transcript carries "worktreePath" only for a worktree-isolated
# spawn; a replacement agent started without isolation has none. $1 is the clone, $2 the
# worktree's own realpath.
agent_id_from_meta() {
    local clone="$1" wt="$2" best_id="" best_mtime=-1 pdir
    pdir="$(projects_dir_for "$clone")"
    [[ -d "$pdir" ]] || return 0
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
    done < <(find "$pdir" -mindepth 3 -maxdepth 3 -type f -name 'agent-*.meta.json' -path '*/subagents/*' 2>/dev/null)
    printf '%s' "$best_id"
}

# $1 is the clone, $2 the agent id.
transcript_for_id() {
    local clone="$1" id="$2" pdir
    pdir="$(projects_dir_for "$clone")"
    [[ -z "$id" || ! -d "$pdir" ]] && return 0
    find "$pdir" -mindepth 3 -maxdepth 3 -type f -name "agent-$id.jsonl" -path '*/subagents/*' 2>/dev/null | head -1
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

# -------------------------------------------------------------------------- clone host labels ---
# The `clone:` line's host label is evidence, never which clone the script happens to run from --
# a Claude Code transcripts directory exists for it, a Codex session names it, or (rarely) both.
# $1 is the clone.
clone_has_claude_transcripts() {
    [[ -d "$(projects_dir_for "$1")" ]]
}

# Whether Codex's own session history names clone $1 as a `cwd` anywhere: a worktree under it
# (from codex_hit_worktrees, already cached) or the clone root itself, plain or `file://`-prefixed
# (a session that ran there without a worktree -- this happens; see the header comment).
clone_has_codex_sessions() {
    local clone="$1" wt
    while IFS= read -r wt; do
        case "$wt" in
            "$clone"/.claude/worktrees/*) return 0 ;;
        esac
    done < <(codex_hit_worktrees)
    [[ -d "$codex_sessions_dir" ]] && command -v rg >/dev/null 2>&1 || return 1
    rg -q --fixed-strings "\"cwd\":\"$clone\"" "$codex_sessions_dir" 2>/dev/null && return 0
    rg -q --fixed-strings "\"cwd\":\"file://$clone\"" "$codex_sessions_dir" 2>/dev/null
}

# ---------------------------------------------------------------------------- collect entries ---
# clone<TAB>path<TAB>branch, one per worktree, across the main checkout and every other clone --
# gathered before any block is printed, so a branch checked out in more than one clone can be
# flagged in both. Plain arrays/strings throughout, not associative arrays (this repo's own
# /bin/bash is 3.2, which predates them), and every array expansion below is guarded by a length
# check first, since 3.2 also treats "${arr[@]}" on a zero-element array as an unset variable
# under `set -u`.
all_entries=()
clones_to_survey=("$main_checkout")
if [[ "${#other_clones[@]}" -gt 0 ]]; then
    clones_to_survey+=("${other_clones[@]}")
fi

# "clone<TAB>label" lines, one per surveyed clone -- computed once per clone rather than once per
# worktree, since clone_has_codex_sessions scans Codex's whole session history.
clone_labels_tsv=""
for clone in "${clones_to_survey[@]}"; do
    has_claude=0; has_codex=0
    clone_has_claude_transcripts "$clone" && has_claude=1
    clone_has_codex_sessions "$clone" && has_codex=1
    if   [[ "$has_claude" -eq 1 && "$has_codex" -eq 1 ]]; then label="claude, codex"
    elif [[ "$has_claude" -eq 1 ]]; then label="claude"
    elif [[ "$has_codex" -eq 1 ]]; then label="codex"
    else label="no known agent activity"
    fi
    clone_labels_tsv+="$clone"$'\t'"$label"$'\n'
done

clone_label_for() {
    printf '%s' "$clone_labels_tsv" | awk -F'\t' -v k="$1" '$1 == k { print $2; exit }'
}

for clone in "${clones_to_survey[@]}"; do
    clone_main="$(main_checkout_of "$clone")"
    while IFS=$'\t' read -r path branch; do
        [[ -z "$path" ]] && continue
        path_real="$(cd "$path" 2>/dev/null && pwd -P)"
        [[ "$path_real" == "$clone_main" ]] && continue
        all_entries+=("$clone"$'\t'"$path"$'\t'"$branch")
    done < <(worktrees_for_clone "$clone")
done

# "branch<TAB>clone" lines, one per entry with a real branch -- looked up per block below with
# awk rather than an associative array, the same reason as codex_hits_tsv above.
branch_owners_tsv=""
if [[ "${#all_entries[@]}" -gt 0 ]]; then
    for entry in "${all_entries[@]}"; do
        IFS=$'\t' read -r clone path branch <<<"$entry"
        [[ "$branch" == "(detached)" ]] && continue
        branch_owners_tsv+="$branch"$'\t'"$clone"$'\n'
    done
fi

# --------------------------------------------------------------------------------- the blocks ---
first=1
if [[ "${#all_entries[@]}" -eq 0 ]]; then
    echo "no agent worktrees"
    exit 0
fi
for entry in "${all_entries[@]}"; do
    IFS=$'\t' read -r clone path branch <<<"$entry"

    [[ "$first" -eq 1 ]] && first=0 || echo
    echo "== $path =="
    echo "clone:       $clone — $(clone_label_for "$clone")"
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

    briefs_dir="$(briefs_dir_for "$clone")"
    slug_branch="${branch//\//-}"
    brief_file="$briefs_dir/$slug_branch.md"
    if [[ -f "$brief_file" ]]; then
        echo "brief:       $brief_file"
    else
        echo "brief:       none"
    fi

    wt_real="$(cd "$path" 2>/dev/null && pwd -P)"
    credit_mtime=""
    credit_label=""
    agent_line=""
    now="$(date +%s)"

    # Credit whichever tool's own evidence exists for this worktree -- never gated by the clone's
    # own label or by which checkout is running the script (see the header comment on
    # projects_dir_for): try this clone's own Claude Code transcripts first, then Codex's.
    agent_id=""
    if [[ -f "$brief_file" ]]; then
        agent_id="$(awk -F': ' '/^agent: /{id=$2} END{print id}' "$brief_file")"
    fi
    [[ -z "$agent_id" ]] && agent_id="$(agent_id_from_meta "$clone" "$wt_real")"

    transcript=""
    [[ -n "$agent_id" ]] && transcript="$(transcript_for_id "$clone" "$agent_id")"

    if [[ -n "$transcript" ]]; then
        mtime="$(mtime_of "$transcript")"
        age_min=$(( (now - mtime) / 60 ))
        if [[ "$age_min" -lt "$WARM_MINUTES" ]]; then verdict="warm"; else verdict="cold"; fi
        agent_line="$agent_id — last write ${age_min}m ago — $verdict"
        credit_mtime="$mtime"
        credit_label="$agent_id"
    fi

    if [[ -z "$agent_line" ]]; then
        codex_result="$(codex_credit_for "$wt_real" "$branch")"
        if [[ -n "$codex_result" ]]; then
            IFS=$'\t' read -r c_nick c_mtime c_note <<<"$codex_result"
            age_min=$(( (now - c_mtime) / 60 ))
            if   (( age_min < CODEX_ACTIVE_MINUTES )); then verdict="active"
            elif (( age_min < CODEX_WARM_MINUTES  )); then verdict="warm"
            else                                            verdict="cold"
            fi
            note_suffix=""
            [[ -n "$c_note" ]] && note_suffix=" ($c_note)"
            agent_line="$c_nick — last write ${age_min}m ago — $verdict$note_suffix"
            credit_mtime="$c_mtime"
            credit_label="$c_nick"
        fi
    fi

    if [[ -n "$agent_line" ]]; then
        echo "agent:       $agent_line"
    else
        echo "agent:       no agent found (no Claude Code transcript, no Codex session)"
    fi

    # Stale ownership: the worktree kept changing well after the credited agent's last write (or
    # nobody is credited at all while it keeps changing) -- the shape a replacement started into
    # this worktree without its `agent:` line being appended leaves behind, for either host.
    activity_epoch="$(worktree_activity_epoch "$path")"
    if [[ -n "$credit_mtime" ]]; then
        drift_min=$(( (activity_epoch - credit_mtime) / 60 ))
        if [[ "$drift_min" -gt "$STALE_MARGIN_MINUTES" ]]; then
            echo "warning:     worktree changed ${drift_min}m after $credit_label's last write — another agent working here? append its agent: line to the brief"
        fi
    elif [[ -z "$credit_label" ]]; then
        recent_min=$(( (now - activity_epoch) / 60 ))
        if [[ "$recent_min" -ge 0 && "$recent_min" -le "$WARM_MINUTES" ]]; then
            echo "warning:     worktree changed ${recent_min}m ago with no credited agent — someone working here? append its agent: line to the brief"
        fi
    fi

    if [[ -n "$branch_owners_tsv" ]]; then
        while IFS= read -r other_clone; do
            [[ -z "$other_clone" || "$other_clone" == "$clone" ]] && continue
            echo "warning:     branch $branch is also checked out in $other_clone — two hosts may be working the same PR"
        done < <(printf '%s' "$branch_owners_tsv" | awk -F'\t' -v b="$branch" '$1 == b { print $2 }')
    fi
done

exit 0
