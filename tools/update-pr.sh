#!/usr/bin/env bash
# The manual sequence that updated a PR branch with main seven times in a row on 2026-09-23
# (#303, #306, #307, #310, #311, #313, #314), each time running the same checks by hand — see
# `tools/decisions.sh M190`, one command brings a pull request up to date with main.
#
#   tools/update-pr.sh <pr-number | branch>            # merge main in, verify, commit, push
#   tools/update-pr.sh --dry-run <pr-number | branch>   # fetch and report only; no worktree touched
#
# Finds the branch's own worktree (`git worktree list`) and works there; if none is checked out
# anywhere, adds a scratch worktree under $TMPDIR for the run and removes it after success only
# when normal worktree removal accepts it. Failed runs retain scratch for diagnosis — a
# branch that already lives in a worktree is never given a second one. Records the branch tip,
# origin/main's tip and their merge base before merging, merges with `--no-ff --no-commit` so even
# a clean merge waits for the commit step below. A branch whose merge base still has the old
# single-file queue, and that edited docs/DECISIONS.md, docs/TODO.md or docs/REVIEW.md, is refused
# before anything is merged, naming the files and pointing at tools/convert-queue-edits.py
# (tools/lib_old_queue.sh), since git can merge such an edit cleanly into the new short files.
# Any unresolved file aborts the merge
# (`git merge --abort`) and names it; nothing is left half-merged. The queue, the records and the
# review list are one file per thing, so two pull requests adding to them no longer meet in one
# file; a branch still on the old single files is converted with tools/convert-queue-edits.py. On a clean result it runs `git diff --cached --check "$main_tip"` (the
# staged result against main's tip as merged, so it judges only what the branch itself brings and a
# whitespace error main already has never fails a branch), `./tools/lint.sh` and
# `./tools/check.sh` (every one of the three has to pass), commits a message naming the three
# revisions and the resolution, and pushes to the branch's own remote — attempted first over
# `origin`'s own configured transport (HTTPS too, under `run`'s own token, once `insteadOf`
# rewrites the SSH form; the invoking user's own login, SSH typically, without `run`), falling back
# to HTTPS through gh's own credential helper, as the same identity, if that attempt is refused.
#
# It never touches the pull request itself: no `gh pr merge`, no enabling auto-merge. The semantic
# review of the merge — whether the result actually reconciles both sides' intent, per the
# merging-main skill — is the merger's, every time; the script only says so and lists the files
# origin/main changed since the merge base, so there is something concrete to review.
#
# Refuses, and does no work, when: the worktree it would operate in is dirty; the branch's local
# tip is behind its own remote (another session pushed since this checkout last fetched it); the
# merge conflicts anywhere; or any of the three checks fails
# (the merge is aborted first, so a failed check leaves nothing staged). Every refusal prints its
# reason and exits non-zero.
#
# UPDATE_PR_CLAUDE=1 appends the repository's Claude co-author trailer to the commit message.
# Unset (the default) leaves it off, since it names a specific assistant and this script's own
# commit and push already carry whichever identity ran it (the player's own, or an agent's under
# `run` -- see below).
#
# **Running this by hand at your own terminal is fine, and unwrapped.** Every GitHub call (the
# origin fetch, the PR-to-branch lookup, the commit, each push attempt) runs through the caller's
# own agent identity when one is set (tools/lib_agent_role.sh's `agent_run`, minting each one a
# fresh token): run this script itself through `uv run python tools/agent-identity.py run <role> --
# tools/update-pr.sh ...`, which sets NAPPY_AGENT_ROLE for `agent_run` to read back. With that
# unset -- a human running it directly, not through an agent's own wrapped call -- `agent_run`
# calls gh/git directly instead, exactly as this script always did. `--dry-run` never reaches a
# write and needs no wrapper either way.
#
# Bash 3.2-safe, like the rest of tools/ -- see tools/lint.sh's own header.
set -uo pipefail

usage() {
    cat <<'EOF'
usage: tools/update-pr.sh [--help|-h] [--dry-run] <pr-number | branch>

Merges origin/main into a pull request's branch: fetches, finds the branch's worktree (or adds a
scratch one under $TMPDIR), merges with --no-ff --no-commit, and aborts naming the files on any
conflict. On a clean result it runs `git diff --cached --check <main tip>` (the staged result
against main's tip as merged, so only the branch's own changes are judged, never whitespace main
already has), `./tools/lint.sh` and
`./tools/check.sh`, commits a message naming the branch tip, main tip, merge base and the
resolution, and pushes it: first over origin's own configured transport (HTTPS with the bot's
token under tools/agent-identity.py run, whatever origin uses -- SSH, say -- with your own login
without it), then, if that is refused, once more over HTTPS through gh's credential helper, as the
same identity. Never merges the pull request itself and never enables auto-merge; says so in its
own output, alongside the files main changed since the merge base, since that review is the
merger's.

Scratch is removed after success only when clean and unlocked. Failed runs retain their
scratch checkout and print its path; dirty/untracked work is never force-removed. An existing
checkout is never removed. If scratch creation fails, only an empty unregistered directory goes.

  --dry-run    Fetch and report what would conflict (via git merge-tree --write-tree), without
               creating, checking out or otherwise touching any worktree. Exits 0 for a clean
               merge, 1 naming the files it would conflict in.

Refuses, with a reason on stderr and a non-zero exit, and does no work when: the worktree it
would operate in is dirty; the branch's local tip is behind its own remote; the branch edited the
old single-file docs/DECISIONS.md, TODO.md or REVIEW.md that main has as files (convert it with
tools/convert-queue-edits.py; --dry-run refuses it too); the merge conflicts;
or git diff --check against main's tip, ./tools/lint.sh or
./tools/check.sh fails (the merge is aborted first).

UPDATE_PR_CLAUDE=1 appends "Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
to the commit message; unset by default, since a human running this should not sign as Claude.

  tools/update-pr.sh 315
  tools/update-pr.sh feature/some-thing
  tools/update-pr.sh --dry-run 315
EOF
}

remote="origin"
dry_run=0
target=""
for arg in "$@"; do
    case "$arg" in
        -h|--help) usage; exit 0 ;;
        --dry-run) dry_run=1 ;;
        -*)
            echo "unknown argument: $arg" >&2
            echo >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ -n "$target" ]]; then
                echo "unexpected extra argument: $arg (already have '$target')" >&2
                echo >&2
                usage >&2
                exit 2
            fi
            target="$arg"
            ;;
    esac
done
if [[ -z "$target" ]]; then
    echo "no PR number or branch given" >&2
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

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git not found" >&2; exit 1; }

# The worktree path that has refs/heads/$1 checked out, or nothing -- same convention as
# tools/agent-status.sh's and tools/prune-merged.sh's own worktree_of().
worktree_of() {
    git worktree list --porcelain | awk -v ref="refs/heads/$1" '
        /^worktree / { path = substr($0, 10) }
        $0 == "branch " ref { print path }'
}

echo "fetching $remote ..."
agent_run git fetch --quiet "$remote" || refuse "git fetch $remote failed"

# ---- resolve the target to a branch name --------------------------------------------------
if [[ "$target" =~ ^[0-9]+$ ]]; then
    command -v gh >/dev/null 2>&1 || refuse "gh is required to resolve PR #$target to a branch name"
    branch="$(agent_run gh pr view "$target" --json headRefName -q .headRefName 2>/dev/null)" \
        || refuse "gh pr view $target failed -- is #$target a real, open pull request?"
    [[ -n "$branch" ]] || refuse "gh pr view $target returned no branch name"
else
    branch="$target"
fi

# ---- ensure a local ref for it, and that it is not behind its own remote ------------------
remote_tip="$(git rev-parse -q --verify "refs/remotes/$remote/$branch" 2>/dev/null || true)"
[[ -n "$remote_tip" ]] || refuse "no $remote/$branch -- does the branch exist and did the fetch above see it?"

if ! git rev-parse -q --verify "refs/heads/$branch" >/dev/null 2>&1; then
    git branch --track "$branch" "$remote/$branch" >/dev/null \
        || refuse "could not create a local branch $branch tracking $remote/$branch"
fi
branch_tip="$(git rev-parse "refs/heads/$branch")"

if [[ "$branch_tip" != "$remote_tip" ]]; then
    if git merge-base --is-ancestor "$branch_tip" "$remote_tip"; then
        refuse "local $branch (${branch_tip:0:8}) is behind $remote/$branch (${remote_tip:0:8})" \
            "-- another session pushed to it; fetch and pull before running this"
    elif ! git merge-base --is-ancestor "$remote_tip" "$branch_tip"; then
        refuse "local $branch (${branch_tip:0:8}) and $remote/$branch (${remote_tip:0:8}) have" \
            "diverged -- reconcile that by hand before running this"
    fi
    # else: local is ahead of its own remote (unpushed local commits) -- not the behind case
    # this refuses, and this script will push its own new commit on top when it is done.
fi

main_tip="$(git rev-parse "refs/remotes/$remote/main")" || refuse "no $remote/main -- fetch failed?"
merge_base="$(git merge-base "$branch_tip" "$main_tip")" \
    || refuse "no merge base between $branch and $remote/main"

echo "branch:     $branch (${branch_tip:0:8})"
echo "main:       $remote/main (${main_tip:0:8})"
echo "merge base: ${merge_base:0:8}"

# A branch cut before the queue became files, that edited the old files, is converted rather than
# merged: git can merge such an edit into the new short files without a conflict.
# shellcheck source=tools/lib_old_queue.sh
source "$root/tools/lib_old_queue.sh"
old_edits="$(old_queue_edits "$branch_tip" "$main_tip")"
if [[ -n "$old_edits" ]]; then
    echo "refusing: $(old_queue_message "$branch" "$old_edits")" >&2
    exit 1
fi

print_review_reminder() {
    echo
    echo "The semantic review of this merge -- whether it reconciles both sides' intent, per the" \
        "merging-main skill -- is yours. Files $remote/main changed since the merge base:"
    git diff --name-only "$merge_base" "$main_tip" | sed 's/^/  /'
}

# ================================================================== --dry-run: report only ===
if [[ "$dry_run" -eq 1 ]]; then
    if git merge-base --is-ancestor "$main_tip" "$branch_tip"; then
        echo "dry run: $branch already contains $remote/main -- nothing to merge"
        print_review_reminder
        exit 0
    fi
    mt_out="$(git merge-tree --write-tree --name-only "$branch_tip" "$main_tip" 2>&1)"
    mt_status=$?
    if [[ "$mt_status" -eq 0 ]]; then
        echo "dry run: merging $remote/main into $branch would be clean"
        print_review_reminder
        exit 0
    fi
    conflicts="$(printf '%s\n' "$mt_out" | sed -n '2,/^$/p' | sed '/^$/d')"
    if [[ -z "$conflicts" ]]; then
        refuse "git merge-tree failed for a reason other than a conflict:" "$mt_out"
    fi
    echo "dry run: merging $remote/main into $branch would conflict in:"
    printf '%s\n' "$conflicts" | sed 's/^/  /'
    print_review_reminder
    exit 1
fi

# ============================================================= real run: find a worktree ===
scratch_wt=""
cleanup() {
    local status=$? registrations
    [[ -n "$scratch_wt" ]] || return 0
    registrations="$(git worktree list --porcelain)" || {
        echo "scratch retained (cannot verify registration): $scratch_wt" >&2
        return 0
    }
    if ! grep -Fxq "worktree $scratch_wt" <<<"$registrations"; then
        # A failed add can leave its mktemp directory behind; rmdir cannot erase any contents.
        rmdir "$scratch_wt" 2>/dev/null \
            || echo "scratch retained (creation failed; directory is not empty): $scratch_wt" >&2
    elif [[ $status -ne 0 ]]; then
        echo "scratch retained after failed run; inspect before cleanup: $scratch_wt" >&2
    elif ! git worktree remove "$scratch_wt"; then
        echo "scratch retained (normal removal refused; inspect dirty files or ownership): $scratch_wt" >&2
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

target_dir="$(worktree_of "$branch")"
if [[ -z "$target_dir" ]]; then
    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    if [[ "$current_branch" == "$branch" ]]; then
        target_dir="$root"
    fi
fi

if [[ -n "$target_dir" ]]; then
    target_dir="$(cd "$target_dir" && pwd -P)"
    if [[ -n "$(git -C "$target_dir" status --porcelain 2>/dev/null)" ]]; then
        refuse "$target_dir ($branch) has uncommitted changes -- commit or stash them first"
    fi
    echo "using existing worktree $target_dir"
else
    scratch_wt="$(mktemp -d "${TMPDIR:-/tmp}/update-pr.XXXXXX")"
    [[ -n "$scratch_wt" ]] || refuse "could not create scratch directory"
    scratch_wt="$(cd "$scratch_wt" && pwd -P)" || refuse "could not resolve scratch directory"
    echo "no worktree has $branch checked out; adding a scratch one at $scratch_wt"
    git worktree add --quiet "$scratch_wt" "$branch" || refuse "git worktree add $scratch_wt $branch failed"
    target_dir="$scratch_wt"
fi

if git merge-base --is-ancestor "$main_tip" "$branch_tip"; then
    echo "$branch already contains $remote/main -- nothing to merge"
    print_review_reminder
    exit 0
fi

# ---- the merge itself ----------------------------------------------------------------------
if ! git -C "$target_dir" merge --no-ff --no-commit "$remote/main" >/tmp/update-pr-merge.$$ 2>&1; then
    cat /tmp/update-pr-merge.$$ >&2
    rm -f /tmp/update-pr-merge.$$

    unresolved="$(git -C "$target_dir" diff --name-only --diff-filter=U)"
    if [[ -n "$unresolved" ]]; then
        git -C "$target_dir" merge --abort
        echo "refusing: merge aborted -- unresolved:" >&2
        printf '%s\n' "$unresolved" | sed 's/^/  /' >&2
        exit 1
    fi
else
    rm -f /tmp/update-pr-merge.$$
fi

# ---- verify before committing anything -------------------------------------------------------
run_check() {
    local label="$1"
    shift
    if ! ( cd "$target_dir" && "$@" ) >/tmp/update-pr-check.$$ 2>&1; then
        cat /tmp/update-pr-check.$$ >&2
        rm -f /tmp/update-pr-check.$$
        git -C "$target_dir" merge --abort 2>/dev/null
        refuse "$label failed -- the merge is aborted, nothing was committed (output above)"
    fi
    rm -f /tmp/update-pr-check.$$
}
# Against main's tip, not the branch's own: the staged merge result minus main is what the branch
# brings (plus any resolution), so whitespace main already carries is not blamed on the branch.
run_check "git diff --cached --check $main_tip" git diff --cached --check "$main_tip"
run_check "./tools/lint.sh" ./tools/lint.sh
run_check "./tools/check.sh" ./tools/check.sh

# ---- commit, naming the three revisions -----------------------------------
commit_msg="Merge $remote/main (${main_tip:0:8}) into $branch (was ${branch_tip:0:8}, base ${merge_base:0:8}).

No conflicts; merged cleanly."
if [[ -n "${UPDATE_PR_CLAUDE:-}" ]]; then
    commit_msg="$commit_msg

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
fi

agent_run git -C "$target_dir" commit --quiet -m "$commit_msg" || refuse "git commit failed"
echo "committed $(git -C "$target_dir" rev-parse --short HEAD) on $branch"

# ---- push, over origin's own configured transport first, gh's own HTTPS credential helper next -
# Each push mints its own fresh installation token (tools/lib_agent_role.sh's `agent_run`) rather
# than relying on the one this script may itself have been wrapped in. Under `run`, the first
# attempt already goes out over HTTPS with that token (`insteadOf` rewrites an SSH `origin`), and
# the second is the same bot over an explicit HTTPS URL. Without a role, the first attempt uses
# `origin`'s own transport and the invoking user's login for it (SSH, typically), and the second
# is that same user over HTTPS through gh's own credential helper. Either way the second attempt
# changes the transport, never the identity.
if agent_run git -C "$target_dir" push --quiet "$remote" "HEAD:refs/heads/$branch"; then
    echo "pushed to $remote/$branch"
else
    echo "push over origin's own transport failed; falling back to HTTPS via gh's credential helper" >&2
    origin_url="$(git -C "$target_dir" remote get-url "$remote")"
    https_url="$(printf '%s' "$origin_url" | sed -E 's#^git@([^:]+):#https://\1/#')"
    case "$https_url" in
        *.git) ;;
        *) https_url="$https_url.git" ;;
    esac
    agent_run git -C "$target_dir" -c credential.helper= -c credential.helper='!gh auth git-credential' \
        push --quiet "$https_url" "HEAD:refs/heads/$branch" \
        || refuse "push failed over both origin's own transport and gh's credential helper ($https_url)"
    echo "pushed to $https_url refs/heads/$branch"
fi

print_review_reminder
