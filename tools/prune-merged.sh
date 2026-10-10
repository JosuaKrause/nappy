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
# local tip is equal to or an ancestor of the commit that pull request merged. The worktree goes
# with `git worktree remove` and never `--force` or automatic unlocking, so a worktree with
# uncommitted changes is refused by git itself and its branch is kept.
#
# Being that narrow is what lets `.claude/settings.json` allow this script outright, where Claude
# Code's auto-mode classifier refuses a bare `git worktree remove` or `git branch -D`.
#
# Every GitHub call (gh pr view, git ls-remote, and the remote branch delete itself) runs through
# the caller's own agent identity when one is set (tools/lib_agent_role.sh's `agent_run`, minting
# each one a fresh token): run this script itself through `uv run python tools/agent-identity.py
# run <role> -- tools/prune-merged.sh ...`, which sets NAPPY_AGENT_ROLE for `agent_run` to read
# back. Run bare, with NAPPY_AGENT_ROLE unset, it calls gh/git directly instead -- exactly what a
# human running it by hand at their own terminal already got.
#
# Bash 3.2-safe, like the rest of tools/ — see tools/lint.sh's own header.
set -uo pipefail

# The ignored paths a worktree may still hold and be removed, because the repository or the OS
# regenerates them: Godot's import cache, the Python environment and its caches, Finder metadata,
# the baked atlas pages (tools/bake-atlases.sh), the Web-template compiler scratch, and the
# `.gdignore` that export-web.sh and build-web-template.sh drop into `build/`. A non-forced `git
# worktree remove` deletes ignored files without a word and `git status` never lists them, so
# anything else ignored (a recording or a capture under `build/`, a `.env` holding a token) keeps
# the worktree. An entry with a `/` inside it is anchored at the worktree's root; one without
# matches at any depth.
REGENERABLE_IGNORED=".godot/ .venv/ __pycache__/ .mypy_cache/ .ruff_cache/ .DS_Store
  assets/atlases/baked/ build/web-template-work/ build/.gdignore"

# shellcheck source=tools/lib_agent_role.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib_agent_role.sh"

usage() {
    cat <<EOF
usage: tools/prune-merged.sh [--dry-run] <branch> [<branch>...]
       tools/prune-merged.sh --all [--apply|--dry-run]
       tools/prune-merged.sh --help|-h

Removes each branch's worktree, local branch and remote branch, only if its pull request is
MERGED and the local tip equals or is an ancestor of its merged head. Refuses missing commit
objects, open PRs, advanced remote tips, dirty/untracked work, locks, unreleased agent briefs,
and ignored files other than these regenerable caches (an entry with an inner / is anchored):
  $REGENERABLE_IGNORED
Brief headers in the main or target checkout must say "cleanup: ready" to release ownership.
Never unlocks or force-removes worktrees. Protects the main checkout and caller's worktree.

  --all       Discover local branches and allocated worktree sizes; read-only by default.
  --apply     Retire eligible candidates from --all after checking state again.
  --dry-run   Report only; no fetch, ref changes, worktree pruning or deletions.
  --help, -h  Print help without doing work.

Allocated KiB are not a promise of exclusive reclaimable bytes on copy-on-write disks.
Applying also clears the registration of every unlocked worktree whose directory is gone
(git worktree prune), then sweeps worktree-agent-* branches that git branch -d accepts once
their worktree is gone. Run from the main checkout through the PR's own agent identity.

  tools/prune-merged.sh feature/fire-on-her-way
  tools/prune-merged.sh --all
  tools/prune-merged.sh --all --apply
EOF
}

branches=()
all=0 dry=0 apply=0 help=0
bad() { echo "$*" >&2; usage >&2; exit 2; }
for arg in "$@"; do
    case "$arg" in
        -h|--help) help=1 ;;
        --all) all=1 ;;
        --apply) apply=1 ;;
        --dry-run) dry=1 ;;
        -*)        bad "unknown flag: $arg" ;;
        *)         branches+=("$arg") ;;
    esac
done
[[ $all -eq 0 || ${#branches[@]} -eq 0 ]] || bad "--all cannot name branches"
[[ $apply -eq 0 || $all -eq 1 ]] || bad "--apply requires --all"
[[ $apply -eq 0 || $dry -eq 0 ]] || bad "--apply and --dry-run conflict"
[[ $help -eq 0 ]] || { usage; exit 0; }
[[ $all -eq 1 || ${#branches[@]} -gt 0 ]] || bad "no branch given"
for branch in "${branches[@]+"${branches[@]}"}"; do
    git check-ref-format "refs/heads/$branch" >/dev/null || bad "invalid branch: $branch"
done
[[ $all -eq 0 || $apply -eq 1 ]] || dry=1

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

refuse() { reason="$*"; return 1; }
# Sort the ignored files in worktree $1 into regenerable cache roots ("cache<TAB>root") and
# anything else ("keep<TAB>path"); $2 is the branch's own brief, already gated by its release.
classify_ignored() {
    git --no-optional-locks -C "$1" -c core.quotePath=false ls-files --others --ignored \
        --exclude-standard \
        | PRUNE_ALLOWED="$REGENERABLE_IGNORED $2" awk '
            BEGIN { n = split(ENVIRON["PRUNE_ALLOWED"], allow) }
            {
                p = $0; root = ""
                for (i = 1; i <= n && root == ""; i++) {
                    e = allow[i]; dir = substr(e, length(e)) == "/"
                    bare = dir ? substr(e, 1, length(e) - 1) : e
                    if (index(bare, "/")) {
                        if (dir ? index(p, e) == 1 : p == e) root = e
                    } else if (dir) {
                        if (index(p, e) == 1) root = e
                        else if ((k = index(p, "/" e)) > 0) root = substr(p, 1, k + length(e))
                    } else if (p == e || substr(p, length(p) - length(e)) == "/" e) {
                        root = p
                    }
                }
                if (root == "") print "keep\t" p
                else if (!(root in seen)) { seen[root] = 1; print "cache\t" root }
            }'
}
# Allocated KiB of the worktree-relative paths on stdin, inside worktree $1.
kib_of() {
    (cd "$1" && tr '\n' '\0' | xargs -0 du -sk 2>/dev/null) | awk '{s += $1} END {print s + 0}'
}
# Produce a candidate snapshot; every destructive stage checks it again.
inspect() {
    local branch="$1" pr state open remote status brief owner ignored kept count
    reason="" path="" size=0 cache_kib=0
    [[ "$branch" != main && "$branch" != master ]] || { refuse "protected branch"; return 1; }
    tip="$(git rev-parse --verify --quiet "refs/heads/$branch")" || { refuse "no local branch"; return 1; }
    open="$(agent_run gh pr list --head "$branch" --state open --json number -q length)" \
        || { refuse "cannot check open PRs"; return 1; }
    [[ "$open" == 0 ]] || { refuse "an open PR owns this branch"; return 1; }
    pr="$(agent_run gh pr view "$branch" --json state,headRefOid,number \
        -q '.state + " " + .headRefOid + " " + (.number | tostring)' 2>/dev/null)" \
        || { refuse "no pull request found"; return 1; }
    read -r state merged_head number <<< "$pr"
    [[ "$state" == MERGED ]] || { refuse "PR #$number is $state, not MERGED"; return 1; }
    git cat-file -e "$merged_head^{commit}" 2>/dev/null \
        || { refuse "merged head unavailable locally; fetch PR #$number explicitly"; return 1; }
    git merge-base --is-ancestor "$tip" "$merged_head" \
        || { refuse "local work is not included in PR #$number"; return 1; }
    remote="$(agent_run git ls-remote --heads origin "refs/heads/$branch")" \
        || { refuse "cannot verify remote branch"; return 1; }
    remote_tip="$(printf '%s\n' "$remote" | cut -f1)"
    [[ -z "$remote_tip" || "$remote_tip" == "$merged_head" ]] \
        || { refuse "remote tip is not the merged head"; return 1; }
    path="$(worktree_of "$branch")"
    if [[ -n "$path" ]]; then
        [[ -d "$path" ]] || {
            refuse "worktree directory is gone; an applying run unregisters it, then retire again"
            return 1
        }
        path="$(cd "$path" && pwd -P)"
        [[ "$path" != "$main_checkout" ]] || { refuse "checked out in main checkout"; return 1; }
        case "$here/" in "$path"/*) refuse "caller is in this worktree"; return 1 ;; esac
        if git worktree list --porcelain | awk -v p="$path" '
            /^worktree / { match_path = substr($0, 10) == p }
            match_path && /^locked/ { found = 1 }
            END { exit !found }'; then
            refuse "worktree is locked"; return 1
        fi
        status="$(git --no-optional-locks -C "$path" status --porcelain --untracked-files=all)" \
            || { refuse "cannot read worktree status"; return 1; }
        [[ -z "$status" ]] || { refuse "dirty or untracked work"; return 1; }
        ignored="$(classify_ignored "$path" ".claude/briefs/${branch//\//-}.md")" \
            || { refuse "cannot list ignored files"; return 1; }
        kept="$(printf '%s\n' "$ignored" | awk -F'\t' '$1 == "keep" {print $2}')"
        if [[ -n "$kept" ]]; then
            count="$(printf '%s\n' "$kept" | wc -l | tr -d ' ')"
            refuse "ignored files present ($count, $(printf '%s\n' "$kept" | kib_of "$path") KiB):" \
                "$(printf '%s\n' "$kept" | head -3 | paste -sd ' ' -)$([[ $count -le 3 ]] || echo ' ...')"
            return 1
        fi
        cache_kib="$(printf '%s\n' "$ignored" | awk -F'\t' '$1 == "cache" {print $2}' | kib_of "$path")"
        size="$(du -sk "$path" | awk '{print $1}')" || { refuse "cannot measure worktree"; return 1; }
    fi
    # An agent's brief claims ownership until explicitly released by its owner.
    for owner in "$main_checkout" "${path:-$main_checkout}"; do
        brief="$owner/.claude/briefs/${branch//\//-}.md"
        if [[ -f "$brief" ]]; then
            [[ "$(sed '/^$/q' "$brief" | sed -n 's/^cleanup: //p' | tail -1)" == ready ]] \
                || { refuse "agent ownership is not released in $brief"; return 1; }
        fi
    done
}
if [[ $all -eq 1 ]]; then
    while IFS= read -r branch; do
        case "$branch" in main|master|worktree-agent-*) continue ;; esac
        branches+=("$branch")
    done < <(git for-each-ref --format='%(refname:short)' refs/heads/)
fi
for branch in "${branches[@]+"${branches[@]}"}"; do
    if ! inspect "$branch"; then
        echo "keep $branch: $reason"
        [[ $all -eq 1 ]] || failed=1
        continue
    fi
    echo "eligible $branch: PR #$number, ${size} KiB (${cache_kib} KiB regenerable ignored caches)," \
        "${path:-no worktree}"
    [[ $dry -eq 0 ]] || continue
    expected_tip="$tip" expected_head="$merged_head" expected_path="$path" expected_remote="$remote_tip"
    if ! inspect "$branch" || [[ "$tip $merged_head $path $remote_tip" != "$expected_tip $expected_head $expected_path $expected_remote" ]]; then
        echo "keep $branch: state changed before retirement (${reason:-snapshot changed})" >&2
        failed=1; continue
    fi
    # Delete the remote first with a lease: a concurrent remote advance keeps all local work.
    if [[ -n "$remote_tip" ]]; then
        if ! agent_run git push --quiet --force-with-lease="refs/heads/$branch:$remote_tip" origin --delete "$branch"; then
            echo "keep $branch: remote delete failed; local work kept" >&2
            failed=1; continue
        fi
        echo "deleted origin/$branch"
    fi
    if ! inspect "$branch" || [[ "$tip $merged_head $path" != "$expected_tip $expected_head $expected_path" ]]; then
        echo "keep $branch locally: state changed (${reason:-snapshot changed})" >&2
        failed=1; continue
    fi
    if [[ -n "$path" ]] && ! git worktree remove "$path"; then
        echo "keep $branch: worktree removal refused" >&2
        failed=1; continue
    fi
    # Atomic compare-and-delete keeps an intervening local commit instead of losing it.
    if git update-ref -d "refs/heads/$branch" "$expected_tip"; then
        echo "deleted $branch (PR #$number merged)"
    else
        failed=1
    fi
done

# A `worktree-agent-<id>` branch belongs to the worktree `.../agent-<id>`, which usually has a
# feature branch checked out rather than this one — so "is it checked out" says nothing, and the
# test is whether that worktree still exists. A live agent's is kept. First drop the registration
# of every worktree whose directory is gone (`git worktree prune` leaves locked ones alone), or a
# hand-deleted worktree would stay registered for good: its branch refused above and its harness
# branch counted as live below.
if [[ $dry -eq 0 ]]; then
git worktree prune
live_worktrees="$(git worktree list --porcelain | awk '/^worktree /{print substr($0, 10)}')"
for agent_branch in $(git for-each-ref --format='%(refname:short)' 'refs/heads/worktree-agent-*'); do
    if grep -q "/${agent_branch#worktree-}\$" <<<"$live_worktrees"; then
        continue
    fi
    if [[ -z "$(worktree_of "$agent_branch")" ]] && out="$(git branch -d "$agent_branch" 2>&1)"; then
        echo "$out"
    fi
done
fi

exit "$failed"
