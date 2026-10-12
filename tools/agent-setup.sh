#!/usr/bin/env bash
# Sets an implementation agent up: the sparse worktree, its brief's header, and the prompt that
# spawns it -- the sequence the orchestrating skill used to ask for by hand, every time.
#
#   tools/agent-setup.sh <name> <branch> [--include <path>...]
#   tools/agent-setup.sh --agent <branch> <id>
#   tools/agent-setup.sh --release <branch>
#   tools/agent-setup.sh --detach <ref> <name> [--include <path>...]
#
# Bash 3.2-safe, like the rest of tools/. Run it from any checkout of the repository; the
# worktree and the brief always go to the main checkout (the first entry of `git worktree list`),
# where tools/agent-status.sh and tools/prune-merged.sh look for them.
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/lib_disk_headroom.sh
source "$script_dir/lib_disk_headroom.sh"

usage() {
    cat <<'EOF_USAGE'
usage: tools/agent-setup.sh <name> <branch> [--include <path>...]
       tools/agent-setup.sh --agent <branch> <id>
       tools/agent-setup.sh --release <branch>
       tools/agent-setup.sh --detach <ref> <name> [--include <path>...]
       tools/agent-setup.sh --help|-h

Sets up an implementation agent. With a name and a branch it:
  - checks disk headroom (tools/lib_disk_headroom.sh) before writing anything;
  - refuses a worktree, local or remote branch, or brief that already exists;
  - makes .claude/worktrees/<name> on a new <branch> from origin/main, sparse, with no upstream
    (the branch does not track origin/main; the first push sets its own);
  - writes the brief's header to .claude/briefs/<branch with / as ->.md in the main checkout
    (branch, worktree, spawned) for the orchestrator to append the task to;
  - prints the prompt that starts the agent.

The sparse patterns are the gates job's sparse checkout in .github/workflows/ci.yml on
origin/main (one list, so the checks that read docs/evidence/ keep what they read), then
!/docs/reference/ and !/docs/style-references/. --include <path> adds a repository path back
(docs/reference/ for a task that needs the photographs); it may be repeated.

  --agent <branch> <id>   appends "agent: <id>" to the brief's header, the newest last. Do it the
                          moment a spawned or replacement agent's id is known.
  --release <branch>      adds "cleanup: ready" to the header, which tools/prune-merged.sh needs
                          before it removes the worktree. Only after the agent's processes stop.
  --detach <ref> <name>   a review agent's scratch checkout: the same sparse worktree under
                          .claude/worktrees/<name>, detached at <ref> (a commit, or a branch
                          fetched from origin), with no branch and no brief, so agent-status.sh
                          never counts it as an agent. Remove it with `git worktree remove`.
  --help, -h              print this and do nothing else.

  tools/agent-setup.sh jolly-bunny feature/jolly-bunny-agent-setup
  tools/agent-setup.sh quiet-yak feature/quiet-yak --include docs/reference/
  tools/agent-setup.sh --agent feature/quiet-yak a1b2c3d4e5f60789
  tools/agent-setup.sh --release feature/quiet-yak
  tools/agent-setup.sh --detach origin/feature/quiet-yak review-quiet-yak
EOF_USAGE
}

bad() { echo "tools/agent-setup.sh: $*" >&2; usage >&2; exit 2; }

mode=setup
positional=()
includes=()
expect_include=0
for arg in "$@"; do
    if [[ $expect_include -eq 1 ]]; then
        [[ "$arg" != -* ]] || bad "--include needs a path, got: $arg"
        includes+=("$arg")
        expect_include=0
        continue
    fi
    case "$arg" in
        -h|--help) usage; exit 0 ;;
        --agent|--release|--detach)
            [[ $mode == setup ]] || bad "only one of --agent, --release, --detach"
            mode="${arg#--}" ;;
        --include) expect_include=1 ;;
        -*)        bad "unknown flag: $arg" ;;
        *)         positional+=("$arg") ;;
    esac
done
[[ $expect_include -eq 0 ]] || bad "--include needs a path"
[[ $mode == setup || $mode == detach || ${#includes[@]} -eq 0 ]] \
    || bad "--include belongs to the setup and --detach forms"
case "$mode" in
    setup)   [[ ${#positional[@]} -eq 2 ]] || bad "expected <name> <branch>" ;;
    agent)   [[ ${#positional[@]} -eq 2 ]] || bad "--agent expects <branch> <id>" ;;
    release) [[ ${#positional[@]} -eq 1 ]] || bad "--release expects <branch>" ;;
    detach)  [[ ${#positional[@]} -eq 2 ]] || bad "--detach expects <ref> <name>" ;;
esac

if [[ $mode == setup || $mode == detach ]]; then
    if [[ $mode == setup ]]; then
        name="${positional[0]}" branch="${positional[1]}"
    else
        ref="${positional[0]}" name="${positional[1]}"
        [[ "$ref" != -* ]] || bad "invalid ref: $ref"
    fi
    [[ "$name" =~ ^[a-z0-9][a-z0-9._-]*$ ]] \
        || bad "invalid name (lowercase words and dashes): $name"
else
    branch="${positional[0]}"
fi
if [[ $mode != detach ]]; then
    git check-ref-format "refs/heads/$branch" >/dev/null 2>&1 || bad "invalid branch: $branch"
fi
if [[ $mode == agent ]]; then
    agent_id="${positional[1]}"
    [[ "$agent_id" =~ ^[A-Za-z0-9._-]+$ ]] || bad "invalid agent id: $agent_id"
fi
for inc in "${includes[@]+"${includes[@]}"}"; do
    [[ "$inc" != /* && "$inc" != *..* && "$inc" != *' '* ]] \
        || bad "--include takes a repository-relative path: $inc"
done

git -C "$script_dir" rev-parse --git-dir >/dev/null 2>&1 \
    || { echo "tools/agent-setup.sh: not inside the repository" >&2; exit 1; }
first_worktree="$(git -C "$script_dir" worktree list --porcelain \
    | awk '/^worktree /{print substr($0, 10); exit}')"
main="$(cd "$first_worktree" && pwd -P)"
slug="${branch:-}"; slug="${slug//\//-}"
brief="$main/.claude/briefs/$slug.md"

# Inserts "KEY: VALUE" at the end of the brief's header (before its first blank line, or at the
# end of a file with none), then proves the line is there.
header_add() {
    local key="$1" value="$2" tmp
    tmp="$(mktemp)" || return 1
    awk -v line="$key: $value" '
        !done && /^$/ { print line; done = 1 }
        { print }
        END { if (!done) print line }' "$brief" > "$tmp" || { rm -f "$tmp"; return 1; }
    cat "$tmp" > "$brief"
    rm -f "$tmp"
    sed '/^$/q' "$brief" | grep -qxF "$key: $value" \
        || { echo "tools/agent-setup.sh: $key line did not land in $brief" >&2; return 1; }
}

if [[ $mode == agent || $mode == release ]]; then
    [[ -f "$brief" ]] || { echo "tools/agent-setup.sh: no brief at $brief" >&2; exit 1; }
    if [[ $mode == agent ]]; then
        if sed '/^$/q' "$brief" | grep -qxF "agent: $agent_id"; then
            echo "agent $agent_id is already in $brief"
            exit 0
        fi
        header_add agent "$agent_id" || exit 1
        echo "appended agent: $agent_id to $brief"
    else
        if sed '/^$/q' "$brief" | grep -qxF "cleanup: ready"; then
            echo "$brief already says cleanup: ready"
            exit 0
        fi
        header_add cleanup ready || exit 1
        echo "released: cleanup: ready in $brief"
    fi
    exit 0
fi

# --- setup and --detach -----------------------------------------------------------------------
worktree="$main/.claude/worktrees/$name"
err() { echo "tools/agent-setup.sh: $*" >&2; }
git -C "$main" fetch --quiet origin main || { err "cannot fetch origin main"; exit 1; }
git -C "$main" rev-parse --verify --quiet origin/main >/dev/null \
    || { err "no origin/main"; exit 1; }

# The patterns come from the gates job, so there is one list; refuse rather than guess if the
# workflow no longer has the block. Only the first sparse-checkout block of that job is read.
ci_yml="$(git -C "$main" show origin/main:.github/workflows/ci.yml)" \
    || { err "origin/main has no .github/workflows/ci.yml"; exit 1; }
gates_patterns="$(printf '%s\n' "$ci_yml" | awk '
    /^  [A-Za-z0-9_-]+:[[:space:]]*(#.*)?$/ { injob = ($1 == "gates:"); inblock = 0; next }
    injob && !found && /^[[:space:]]+sparse-checkout:[[:space:]]*\|/ {
        inblock = 1; found = 1; indent = -1; next
    }
    inblock {
        if ($0 ~ /^[[:space:]]*$/) next
        match($0, /^[[:space:]]*/)
        if (indent < 0) indent = RLENGTH
        if (RLENGTH < indent) { inblock = 0; next }
        sub(/^[[:space:]]+/, ""); print
    }')"
[[ -n "$gates_patterns" ]] \
    || { err "no sparse-checkout block in the gates job of .github/workflows/ci.yml on origin/main"
         exit 1; }

failures=0
if [[ -e "$worktree" ]] \
    || git -C "$main" worktree list --porcelain | grep -qxF "worktree $worktree"; then
    err "worktree already exists: $worktree"; failures=1
fi
if [[ $mode == setup ]]; then
    if git -C "$main" show-ref --verify --quiet "refs/heads/$branch"; then
        err "local branch already exists: $branch"; failures=1
    fi
    if git -C "$main" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        err "remote branch already exists: origin/$branch"; failures=1
    fi
    if [[ -e "$brief" ]]; then
        err "brief already exists: $brief"; failures=1
    fi
else
    commit="$(git -C "$main" rev-parse --verify --quiet "$ref^{commit}")" || commit=""
    if [[ -z "$commit" ]] && git -C "$main" fetch --quiet origin "$ref" 2>/dev/null; then
        commit="$(git -C "$main" rev-parse --verify --quiet FETCH_HEAD^{commit})" || commit=""
    fi
    [[ -n "$commit" ]] || { err "cannot resolve $ref to a commit"; failures=1; }
fi
[[ $failures -eq 0 ]] || exit 1

job=worktree-sparse
[[ ${#includes[@]} -eq 0 ]] || job=worktree-full
headroom_preflight tools/agent-setup.sh "$main/.claude/worktrees" "" "$job" || exit 1

patterns="$gates_patterns
!/docs/reference/
!/docs/style-references/"
for inc in "${includes[@]+"${includes[@]}"}"; do
    patterns="$patterns
/${inc#./}"
done

# Nothing is materialized until the sparse patterns are set.
if [[ $mode == setup ]]; then
    git -C "$main" worktree add --quiet --no-checkout --no-track -b "$branch" "$worktree" \
        origin/main || exit 1
else
    git -C "$main" worktree add --quiet --no-checkout --detach "$worktree" "$commit" || exit 1
fi

fail_cleanup() {
    err "$1; removing the half-made worktree"
    git -C "$main" worktree remove --force "$worktree" >/dev/null 2>&1
    [[ $mode != setup ]] || git -C "$main" branch -D "$branch" >/dev/null 2>&1
    exit 1
}
printf '%s\n' "$patterns" \
    | git -C "$worktree" sparse-checkout set --no-cone --stdin >/dev/null 2>&1 \
    || fail_cleanup "git sparse-checkout failed"
git -C "$worktree" checkout --quiet -f HEAD 2>/dev/null || fail_cleanup "checkout failed"
[[ -f "$worktree/CLAUDE.md" ]] || fail_cleanup "the checkout is empty"

if [[ $mode == detach ]]; then
    echo "worktree: $worktree (detached at $commit; no branch, no brief)"
    echo "sparse:   $(printf '%s\n' "$patterns" | tr '\n' ' ')"
    echo "remove:   git worktree remove $worktree"
    exit 0
fi

# --no-track leaves the branch without an upstream; the first push sets its own.
[[ -z "$(git -C "$worktree" config --get "branch.$branch.merge")" ]] \
    || fail_cleanup "the branch has an upstream"

mkdir -p "$main/.claude/briefs"
{
    echo "branch: $branch"
    echo "worktree: $worktree"
    echo "spawned: $(date +%Y-%m-%d)"
    echo
} > "$brief"
grep -qxF "worktree: $worktree" "$brief" \
    || { err "brief header did not land in $brief"; exit 1; }

echo "worktree: $worktree"
echo "brief:    $brief (header only; append the task under it)"
echo "sparse:   $(printf '%s\n' "$patterns" | tr '\n' ' ')"
echo
echo "spawn prompt (start the agent with no worktree isolation, then run"
echo "tools/agent-setup.sh --agent $branch <its id>):"
echo
cat <<PROMPT
You are an implementation agent in the repository at $main. Your worktree is $worktree (already \
on branch $branch from origin/main, sparse). cd there first and use absolute paths under it.

Read your brief at $brief, then the agent contract at \
$worktree/.claude/skills/orchestrating/references/agent-contract.md, and follow both exactly. \
Open a ready PR when done, as the GitHub identity your brief names. Your final message is the \
report the contract asks for.
PROMPT
