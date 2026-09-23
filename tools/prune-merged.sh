#!/usr/bin/env bash
# Retire a branch whose pull request has been squash-merged: its worktree, its local branch and,
# if GitHub has not already deleted it, its remote branch. Then sweep the harness's own
# `worktree-agent-*` branches, which have no pull request and go only where `git branch -d` agrees.
#
#   tools/prune-merged.sh feature/fire-on-her-way
#   tools/prune-merged.sh feature/a feature/b
#
# Git cannot see a squash as a merge, so `git branch -d` refuses every such branch and `-D` would
# delete one with unpushed work just as readily. This script is the committing skill's check made
# executable: nothing is touched unless GitHub says the branch's pull request is MERGED **and** the
# local tip is exactly the commit that pull request merged — the branch then holds nothing `main`
# lacks. The worktree goes with `git worktree remove` and never `--force`, so a worktree with
# uncommitted changes is refused by git itself and its branch is kept.
#
# Being that narrow is what lets `.claude/settings.json` allow this script outright, where Claude
# Code's auto-mode classifier refuses a bare `git worktree remove` or `git branch -D`.
#
# Bash 3.2-safe, like the rest of tools/ — see tools/lint.sh's own header.
set -uo pipefail

usage() {
    cat <<'EOF'
usage: tools/prune-merged.sh [--help|-h] <branch> [<branch>...]

Removes each branch's worktree, local branch and remote branch, only if its pull request is
MERGED and the local tip is the commit that pull request merged. A worktree with uncommitted
changes is refused, and its branch kept. Then deletes worktree-agent-* branches that
`git branch -d` accepts. Run it from the main checkout, not from a worktree it removes.

  tools/prune-merged.sh feature/fire-on-her-way
EOF
}

branches=()
for arg in "$@"; do
    case "$arg" in
        -h|--help) usage; exit 0 ;;
        -*)        echo "unknown flag: $arg" >&2; usage >&2; exit 2 ;;
        *)         branches+=("$arg") ;;
    esac
done
if [[ ${#branches[@]} -eq 0 ]]; then
    echo "no branch given" >&2
    usage >&2
    exit 2
fi

git rev-parse --git-dir >/dev/null || exit 1
here="$(pwd -P)"
# `git worktree list` always names the main checkout first.
main_checkout="$(cd "$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}')" \
    && pwd -P)"
failed=0

# The worktree path that has `refs/heads/$1` checked out, or nothing.
worktree_of() {
    git worktree list --porcelain | awk -v ref="refs/heads/$1" '
        /^worktree / { path = substr($0, 10) }
        $0 == "branch " ref { print path }'
}

for branch in "${branches[@]}"; do
    if ! tip="$(git rev-parse --verify --quiet "refs/heads/$branch")"; then
        echo "skip $branch: no such local branch" >&2
        failed=1
        continue
    fi
    if ! pr="$(gh pr view "$branch" --json state,headRefOid,number \
            -q '.state + " " + .headRefOid + " " + (.number | tostring)' 2>/dev/null)"; then
        echo "skip $branch: no pull request found for it" >&2
        failed=1
        continue
    fi
    read -r state merged_head number <<< "$pr"
    if [[ "$state" != MERGED ]]; then
        echo "skip $branch: PR #$number is $state, not MERGED" >&2
        failed=1
        continue
    fi
    if [[ "$merged_head" != "$tip" ]]; then
        echo "skip $branch: local tip ${tip:0:8} is not PR #$number's merged head" \
            "${merged_head:0:8} — it has commits the PR never carried" >&2
        failed=1
        continue
    fi

    path="$(worktree_of "$branch")"
    if [[ -n "$path" ]]; then
        path="$(cd "$path" && pwd -P)"
        if [[ "$path" == "$main_checkout" ]]; then
            echo "skip $branch: it is checked out in the main checkout; switch that to main first" >&2
            failed=1
            continue
        fi
        case "$here/" in
            "$path"/*)
                echo "skip $branch: the shell is standing in its worktree ($path); run from the" \
                    "main checkout" >&2
                failed=1
                continue ;;
        esac
        git worktree unlock "$path" 2>/dev/null
        if ! git worktree remove "$path"; then
            echo "skip $branch: its worktree $path was not removed (see git's message); branch kept" >&2
            failed=1
            continue
        fi
        echo "removed worktree $path"
    fi

    git branch -D "$branch" >/dev/null && echo "deleted $branch (was ${tip:0:8}, PR #$number merged)"

    remote_tip="$(git ls-remote --heads origin "refs/heads/$branch" | cut -f1)"
    if [[ -n "$remote_tip" ]]; then
        if [[ "$remote_tip" == "$merged_head" ]]; then
            git push --quiet origin --delete "$branch" && echo "deleted origin/$branch"
        else
            echo "kept origin/$branch: its tip ${remote_tip:0:8} is not the merged head" >&2
            failed=1
        fi
    fi
done

# A `worktree-agent-<id>` branch belongs to the worktree `.../agent-<id>`, which usually has a
# feature branch checked out rather than this one — so "is it checked out" says nothing, and the
# test is whether that worktree still exists. A live agent's is kept.
git worktree prune
live_worktrees="$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10)}')"
for agent_branch in $(git for-each-ref --format='%(refname:short)' 'refs/heads/worktree-agent-*'); do
    if printf '%s\n' "$live_worktrees" | grep -q "/${agent_branch#worktree-}\$"; then
        continue
    fi
    if [[ -z "$(worktree_of "$agent_branch")" ]] && out="$(git branch -d "$agent_branch" 2>&1)"; then
        echo "$out"
    fi
done

exit "$failed"
