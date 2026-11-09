#!/usr/bin/env bash
# Exercises tools/agent-setup.sh against a scratch clone: a throwaway "origin" (a bare repository)
# holding a few files, a small .github/workflows/ci.yml with a known gates list, and the script
# itself, cloned to a main checkout the script then runs from.
#
#   tools/test_agent_setup.sh
#
# Asserts:
#   - --help/-h print usage and exit 0; an unknown flag, a missing value, a stray word and a bad
#     name are rejected before any worktree, branch or brief exists
#   - a setup makes the worktree on a new branch with no upstream, sparse by the gates job's list
#     (the evidence SVG and the two experiment runners kept, other evidence, docs/reference/ and
#     docs/style-references/ left out), writes the brief's header (branch, worktree, spawned, then
#     a blank line) and prints a spawn prompt naming the worktree, the brief and the contract
#   - the gates list is read exactly: a job header with a trailing comment ends the job before it,
#     a second sparse-checkout block in the job is ignored, and no gates block refuses
#   - this repository's own ci.yml gives a gates list that starts with /* and keeps evidence SVGs
#   - a second setup of the same worktree, of the same branch and onto an existing brief is refused
#     and changes nothing
#   - --include brings a left-out folder back
#   - --detach makes the same sparse checkout at a commit with no branch and no brief, and refuses
#     an unknown ref and an existing path, and lands on the named branch's head even when another
#     fetch writes FETCH_HEAD between its fetch and its read, and prints the --remove line for it
#   - --remove removes a clean detached checkout, regenerable ignored caches and all, and refuses,
#     leaving the worktree as it stands: a path in place of a name, a name nothing is at, a
#     worktree with a branch, a locked one, the caller's own, one with a changed or an untracked
#     file, one holding an ignored file that is not a regenerable cache, a folder that is not a
#     worktree, and a link under .claude/worktrees/ to a worktree elsewhere
#   - a headroom shortfall refuses before anything is made
#   - --agent appends one line per agent, newest last, and not the same id twice; --release adds
#     "cleanup: ready" once, both even when the line already sits early in a header longer than a
#     pipe holds; both refuse a branch with no brief
#
# Needs nothing but bash and git. Bash 3.2-safe, like the rest of tools/.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

usage() {
    cat <<'EOF'
usage: tools/test_agent_setup.sh [--help|-h]

Runs tools/agent-setup.sh against a scratch clone and checks the worktree, the brief header and
the refusals. Takes no other argument.
EOF
}
case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    "") ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
esac

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

checks=0
failures=0
ok() { checks=$((checks + 1)); echo "ok   $1"; }
fail() { checks=$((checks + 1)); failures=$((failures + 1)); echo "FAIL $1" >&2; }
# $1 label  then a command that must succeed
check() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi
}
# $1 label  then a command that must fail
refuse() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then fail "$label"; else ok "$label"; fi
}
# $1 label  $2 expected  $3 actual
same() { if [[ "$2" == "$3" ]]; then ok "$1"; else fail "$1 (wanted '$2', got '$3')"; fi; }
has() { grep -qF -- "$2" <<<"$1"; }

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com
export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

# A workflow with the shapes the parse must survive: another job with its own block before
# gates, a commented header after it, and a second block inside gates.
write_ci() {
    cat > "$1" <<'EOF'
jobs:
  classify:
    steps:
      - with:
          sparse-checkout: |
            tools

  gates:
    steps:
      - with:
          sparse-checkout-cone-mode: false
          sparse-checkout: |
            /*
            !/docs/evidence/
            /docs/evidence/**/*.svg
            /docs/evidence/a/measure-native.py
            /docs/evidence/b/measure-native.py

      - with:
          sparse-checkout: |
            /*
            !/docs/evidence/

  cost-table:  # the one Godot gate
    steps:
      - with:
          sparse-checkout: |
            /*
            !/docs/evidence/
EOF
}

seed="$work/seed"
mkdir -p "$seed/tools" "$seed/.github/workflows" "$seed/docs/evidence/run" \
    "$seed/docs/evidence/a" "$seed/docs/evidence/b" "$seed/docs/reference" \
    "$seed/docs/style-references" "$seed/src"
git init -q -b main "$seed"
cp "$root/tools/agent-setup.sh" "$root/tools/lib_disk_headroom.sh" \
    "$root/tools/lib_regenerable_ignored.sh" "$seed/tools/"
chmod +x "$seed/tools/agent-setup.sh"
write_ci "$seed/.github/workflows/ci.yml"
echo claude > "$seed/CLAUDE.md"
echo code > "$seed/src/a.gd"
echo big > "$seed/docs/evidence/run/log.txt"
echo '<svg/>' > "$seed/docs/evidence/run/keep.svg"
echo run > "$seed/docs/evidence/a/measure-native.py"
echo run > "$seed/docs/evidence/b/measure-native.py"
echo photo > "$seed/docs/reference/photo.txt"
echo style > "$seed/docs/style-references/s.txt"
git -C "$seed" add -A && git -C "$seed" commit -q -m seed
git clone -q --bare "$seed" "$work/origin.git"
git clone -q "$work/origin.git" "$work/main"
main="$(cd "$work/main" && pwd -P)"
tool="$main/tools/agent-setup.sh"
briefs="$main/.claude/briefs"
count_worktrees() { git -C "$main" worktree list --porcelain | grep -c '^worktree '; }
sparse_line() { sed -n 's/^sparse:   //p' <<<"$1"; }

# --------------------------------------------------------------- help and rejection, no work ---
check "--help exits 0 with usage" bash -c "'$tool' --help | grep -q usage"
check "-h exits 0 with usage" bash -c "'$tool' -h | grep -q usage"
refuse "unknown flag rejected" "$tool" --not-a-flag
refuse "--include missing its path rejected" "$tool" a feature/a --include
refuse "--include on --agent rejected" "$tool" --agent feature/a id --include x
refuse "stray word rejected" "$tool" only-one
refuse "bad name rejected" "$tool" 'Bad Name' feature/a
refuse "bad branch rejected" "$tool" a 'bad..branch'
refuse "--agent and --release together rejected" "$tool" --agent --release feature/a id
refuse "--include of an absolute path rejected" "$tool" a feature/a --include /etc
refuse "--detach without a name rejected" "$tool" --detach HEAD
refuse "--remove without a name rejected" "$tool" --remove
refuse "--remove with two names rejected" "$tool" --remove one two
refuse "--remove with --include rejected" "$tool" --remove one --include docs/reference/
refuse "--remove and --detach together rejected" "$tool" --remove --detach HEAD one
refuse "--remove of an absolute path rejected" "$tool" --remove "$work/main"
refuse "--remove of a path that climbs out rejected" "$tool" --remove ../../main
refuse "--remove of a path under the worktrees folder rejected" "$tool" --remove a/b
if [[ "$(count_worktrees)" -eq 1 && ! -e "$briefs" && ! -e "$main/.claude/worktrees" ]]; then
    ok "rejections made no worktree and no brief"
else
    fail "rejections made no worktree and no brief"
fi

# -------------------------------------------------------------------------------------- setup ---
out="$("$tool" alpha feature/alpha 2>&1)"; status=$?
if [[ $status -eq 0 ]]; then ok "setup exits 0"; else fail "setup exits 0"; echo "$out" >&2; fi
wt="$main/.claude/worktrees/alpha"
same "worktree is on the new branch" feature/alpha "$(git -C "$wt" branch --show-current)"
same "worktree starts at origin/main" "$(git -C "$main" rev-parse origin/main)" \
    "$(git -C "$wt" rev-parse HEAD)"
refuse "branch has no upstream" git -C "$wt" rev-parse --abbrev-ref 'feature/alpha@{upstream}'
check "tracked code is present" test -f "$wt/src/a.gd"
check "evidence SVG kept by the gates list" test -f "$wt/docs/evidence/run/keep.svg"
check "first experiment runner kept" test -f "$wt/docs/evidence/a/measure-native.py"
check "second experiment runner kept" test -f "$wt/docs/evidence/b/measure-native.py"
check "other evidence left out" test ! -e "$wt/docs/evidence/run/log.txt"
check "docs/reference left out" test ! -e "$wt/docs/reference/photo.txt"
check "docs/style-references left out" test ! -e "$wt/docs/style-references/s.txt"
want='/* !/docs/evidence/ /docs/evidence/**/*.svg '
want="$want/docs/evidence/a/measure-native.py /docs/evidence/b/measure-native.py "
want="$want!/docs/reference/ !/docs/style-references/ "
same "the pattern list is exactly the first gates block, then the two exclusions" \
    "$want" "$(sparse_line "$out")"
brief="$briefs/feature-alpha.md"
check "brief header has branch" grep -qx 'branch: feature/alpha' "$brief"
check "brief header has worktree" grep -qxF "worktree: $wt" "$brief"
check "brief header has spawned date" grep -qE '^spawned: [0-9]{4}-[0-9]{2}-[0-9]{2}$' "$brief"
same "brief header ends with a blank line" "" "$(sed -n 4p "$brief")"
check "prompt names the worktree" has "$out" "Your worktree is $wt"
check "prompt names the brief" has "$out" "Read your brief at $brief"
check "prompt names the contract" has "$out" "references/agent-contract.md"

# ---------------------------------------------------------------------------------- refusals ---
cp "$brief" "$work/brief-before"
refuse "same worktree refused" "$tool" alpha feature/other
refuse "same branch refused" "$tool" beta feature/alpha
check "refusals left the brief alone" cmp -s "$brief" "$work/brief-before"
same "refusals made no other worktree" 2 "$(count_worktrees)"
git -C "$main" push -q origin HEAD:refs/heads/feature/remote-only
refuse "existing remote branch refused" "$tool" gamma feature/remote-only
check "remote refusal made no worktree" test ! -e "$main/.claude/worktrees/gamma"
mkdir -p "$briefs" && echo "branch: feature/delta" > "$briefs/feature-delta.md"
refuse "existing brief refused" "$tool" delta feature/delta
check "brief refusal made no worktree" test ! -e "$main/.claude/worktrees/delta"
check "brief refusal made no branch" \
    bash -c "! git -C '$main' show-ref --verify --quiet refs/heads/feature/delta"
NAPPY_HEADROOM_PEAK_MIB_WORKTREE_SPARSE=999999999 refuse "headroom shortfall refused" \
    "$tool" eps feature/eps
check "headroom refusal made no worktree" test ! -e "$main/.claude/worktrees/eps"
check "headroom refusal made no brief" test ! -e "$briefs/feature-eps.md"

# ------------------------------------------------------------------------------------ include ---
"$tool" zeta feature/zeta --include docs/reference/ >/dev/null 2>&1
check "--include brings docs/reference back" \
    test -f "$main/.claude/worktrees/zeta/docs/reference/photo.txt"
check "--include leaves docs/style-references out" \
    test ! -e "$main/.claude/worktrees/zeta/docs/style-references/s.txt"

# ------------------------------------------------------------------------------------- detach ---
head_sha="$(git -C "$main" rev-parse origin/main)"
dout="$("$tool" --detach origin/main review-one 2>&1)"; status=$?
if [[ $status -eq 0 ]]; then
    ok "--detach exits 0"
else
    fail "--detach exits 0"; echo "$dout" >&2
fi
dwt="$main/.claude/worktrees/review-one"
same "--detach leaves HEAD detached" "" "$(git -C "$dwt" branch --show-current)"
same "--detach is at the ref" "$head_sha" "$(git -C "$dwt" rev-parse HEAD)"
check "--detach keeps the evidence SVG" test -f "$dwt/docs/evidence/run/keep.svg"
check "--detach leaves docs/reference out" test ! -e "$dwt/docs/reference/photo.txt"
same "--detach uses the same patterns" "$(sparse_line "$out")" "$(sparse_line "$dout")"
check "--detach writes no brief" test ! -e "$briefs/review-one.md"
# A stale local tracking ref must not win: push a new commit to origin from another clone.
git clone -q "$work/origin.git" "$work/pusher"
git -C "$work/pusher" checkout -q -b feature/live
echo more > "$work/pusher/src/b.gd"
git -C "$work/pusher" add -A && git -C "$work/pusher" commit -q -m live
git -C "$work/pusher" push -q origin feature/live
git -C "$main" fetch -q origin feature/live:refs/remotes/origin/feature/live
echo newer > "$work/pusher/src/c.gd"
git -C "$work/pusher" add -A && git -C "$work/pusher" commit -q -m newer
git -C "$work/pusher" push -q origin feature/live
new_sha="$(git -C "$work/pusher" rev-parse HEAD)"
stale_sha="$(git -C "$main" rev-parse origin/feature/live)"
"$tool" --detach origin/feature/live review-live >/dev/null 2>&1
same "--detach origin/<branch> lands on the remote's current head, not the stale ref" \
    "$new_sha" "$(git -C "$main/.claude/worktrees/review-live" rev-parse HEAD 2>/dev/null)"
check "the stale local ref was behind" test "$stale_sha" != "$new_sha"
"$tool" --detach feature/live review-bare >/dev/null 2>&1
same "--detach of a bare branch name lands on the remote's head" \
    "$new_sha" "$(git -C "$main/.claude/worktrees/review-bare" rev-parse HEAD 2>/dev/null)"
"$tool" --detach "$head_sha" review-sha >/dev/null 2>&1
same "--detach of a SHA lands on it" \
    "$head_sha" "$(git -C "$main/.claude/worktrees/review-sha" rev-parse HEAD 2>/dev/null)"
# Another agent's fetch lands between ours and our read: a git wrapper that fetches a decoy branch
# after every fetch the tool makes leaves FETCH_HEAD naming the decoy, so a read of FETCH_HEAD
# detaches at the wrong commit.
git -C "$work/pusher" checkout -q -b feature/decoy origin/main
echo decoy > "$work/pusher/src/d.gd"
git -C "$work/pusher" add -A && git -C "$work/pusher" commit -q -m decoy
git -C "$work/pusher" push -q origin feature/decoy
decoy_sha="$(git -C "$work/pusher" rev-parse HEAD)"
real_git="$(command -v git)"
mkdir -p "$work/racebin"
cat > "$work/racebin/git" <<EOF
#!/usr/bin/env bash
"$real_git" "\$@"; rc=\$?
for a in "\$@"; do
    if [[ \$a == fetch ]]; then "$real_git" -C "$main" fetch -q origin feature/decoy; break; fi
done
exit \$rc
EOF
chmod +x "$work/racebin/git"
PATH="$work/racebin:$PATH" "$tool" --detach origin/feature/live review-race >/dev/null 2>&1
same "--detach ignores a fetch another agent makes in between" \
    "$new_sha" "$(git -C "$main/.claude/worktrees/review-race" rev-parse HEAD 2>/dev/null)"
check "the race wrapper left FETCH_HEAD on the decoy" \
    test "$(cut -c1-40 "$main/.git/FETCH_HEAD" | head -1)" = "$decoy_sha"
refuse "--detach of an unknown ref refused" "$tool" --detach no-such-ref review-two
check "--detach refusal made no worktree" test ! -e "$main/.claude/worktrees/review-two"
refuse "--detach onto an existing path refused" "$tool" --detach origin/main review-one

# ------------------------------------------------------------------------------------- remove ---
check "--detach prints the --remove line for its checkout" \
    has "$dout" "remove:   tools/agent-setup.sh --remove review-one"
registered() { git -C "$main" worktree list --porcelain | grep -qxF "worktree $main/.claude/worktrees/$1"; }
# $1 label  $2 the worktree's name  $3 the words the refusal must hold
remove_refused() {
    local out status
    out="$("$tool" --remove "$2" 2>&1)"; status=$?
    if [[ $status -ne 0 ]] && has "$out" "$3" && [[ -d "$main/.claude/worktrees/$2" ]]; then
        ok "$1"
    else
        fail "$1 (exit $status: $out)"
    fi
}
# The ignore rules every worktree of the scratch clone reads: a cache the repository regenerates,
# and a build folder whose content it does not.
mkdir -p "$main/.git/info"
printf '.venv/\nbuild/\n' >> "$main/.git/info/exclude"

refuse "--remove of a name nothing is at exits non-zero" "$tool" --remove no-such-checkout
remove_refused "--remove of an agent's worktree (it has a branch) refused" alpha "has the branch feature/alpha"
check "the refused agent's worktree is still registered" registered alpha

echo edited >> "$dwt/src/a.gd"
remove_refused "--remove with a changed file refused" review-one "changed or untracked files"
git -C "$dwt" checkout -q -- src/a.gd
echo notes > "$dwt/review-notes.txt"
remove_refused "--remove with an untracked file refused" review-one "changed or untracked files"
rm "$dwt/review-notes.txt"
mkdir -p "$dwt/build"
echo capture > "$dwt/build/capture.txt"
remove_refused "--remove with an ignored file that is no cache refused" review-one \
    "ignored files that are not regenerable caches"
rm -r "$dwt/build"
git -C "$main" worktree lock "$dwt"
remove_refused "--remove of a locked worktree refused" review-one "is locked"
git -C "$main" worktree unlock "$dwt"
if (cd "$dwt/src" && "$tool" --remove review-one) >/dev/null 2>&1; then
    fail "--remove from inside the worktree refused"
else
    ok "--remove from inside the worktree refused"
fi
check "the worktree outlived every refusal" registered review-one

mkdir -p "$main/.claude/worktrees/plain-folder"
remove_refused "--remove of a folder that is no worktree refused" plain-folder "is not a worktree of this repository"
rmdir "$main/.claude/worktrees/plain-folder"
git -C "$main" worktree add -q --detach "$work/elsewhere" origin/main
ln -s "$work/elsewhere" "$main/.claude/worktrees/linked-out"
remove_refused "--remove of a link to a worktree elsewhere refused" linked-out "resolves outside .claude/worktrees/"
check "the worktree elsewhere is untouched" test -f "$work/elsewhere/CLAUDE.md"
rm "$main/.claude/worktrees/linked-out"

# Clean, with a regenerable cache in it: removed, by git's own unforced removal.
mkdir -p "$dwt/.venv"
echo cache > "$dwt/.venv/pyvenv.cfg"
rout="$("$tool" --remove review-one 2>&1)"; status=$?
if [[ $status -eq 0 ]] && has "$rout" "removed: $dwt"; then
    ok "--remove of a clean detached checkout exits 0 and says so"
else
    fail "--remove of a clean detached checkout exits 0 and says so (exit $status: $rout)"
fi
check "--remove took the directory" test ! -e "$dwt"
refuse "--remove unregistered the worktree" registered review-one
check "--remove touched no other worktree" registered review-live
check "--remove deleted no branch" git -C "$main" show-ref --verify --quiet refs/heads/feature/alpha
refuse "a second --remove of the same name refused" "$tool" --remove review-one

# ------------------------------------------------------------------- --agent and --release ---
"$tool" --agent feature/alpha id-one >/dev/null 2>&1
"$tool" --agent feature/alpha id-two >/dev/null 2>&1
"$tool" --agent feature/alpha id-two >/dev/null 2>&1
same "agent lines are one per id, newest last" '4:agent: id-one 5:agent: id-two ' \
    "$(grep -n '^agent: ' "$brief" | tr '\n' ' ')"
same "agent lines stay in the header" "" "$(sed -n 6p "$brief")"
"$tool" --release feature/alpha >/dev/null 2>&1
"$tool" --release feature/alpha >/dev/null 2>&1
same "cleanup: ready added once" 1 "$(grep -c '^cleanup: ready$' "$brief")"
same "the header still ends at the first blank line" 6 "$(sed '/^$/q' "$brief" | grep -c .)"
# A header far larger than a pipe holds, its agent and cleanup lines first: a search piped from
# sed that matches and leaves while sed still writes would fail the pipe and read as a miss.
big_brief="$briefs/feature-big.md"
{
    printf 'branch: feature/big\nagent: id-big\ncleanup: ready\n'
    for i in $(seq 1 20000); do printf 'note-%05d: padding\n' "$i"; done
    printf '\n# Task\n'
} > "$big_brief"
check "--agent with its line early in a long header says it is already there" \
    bash -c "'$tool' --agent feature/big id-big | grep -q 'already in'"
same "--agent does not add that line twice" 1 "$(grep -c '^agent: id-big$' "$big_brief")"
check "--release with its line early in a long header says it is already there" \
    bash -c "'$tool' --release feature/big | grep -q 'already says'"
same "--release does not add that line twice" 1 "$(grep -c '^cleanup: ready$' "$big_brief")"
refuse "--agent with no brief refused" "$tool" --agent feature/nothing id
refuse "--release with no brief refused" "$tool" --release feature/nothing

# ------------------------------------------------------------ the gates list, as the file is ---
# Each case edits origin's ci.yml on main and sets up a worktree from it.
publish_ci() {
    local clone="$work/edit"
    rm -rf "$clone"
    git clone -q "$work/origin.git" "$clone"
    "$1" "$clone/.github/workflows/ci.yml"
    git -C "$clone" commit -q -am "$2" && git -C "$clone" push -q origin HEAD:main
}
no_gates_block() { sed -i.bak 's/^  gates:$/  other:/' "$1"; rm -f "$1.bak"; }
publish_ci no_gates_block "no gates job"
refuse "no gates block refused" "$tool" noblock feature/noblock
check "no gates block made no worktree" test ! -e "$main/.claude/worktrees/noblock"
check "no gates block made no branch" \
    bash -c "! git -C '$main' show-ref --verify --quiet refs/heads/feature/noblock"
commented_gates() { sed -i.bak 's/^  other:$/  gates:  # the checks/' "$1"; rm -f "$1.bak"; }
publish_ci commented_gates "commented gates header"
cout="$("$tool" commented feature/commented 2>&1)"
check "a gates header with a trailing comment still gives its list" \
    has "$cout" '/* !/docs/evidence/ /docs/evidence/**/*.svg'

# This repository's own ci.yml: its gates list opens with /* and keeps the evidence SVGs.
real="$work/real"
mkdir -p "$real/tools" "$real/.github/workflows"
git init -q -b main "$real"
cp "$root/tools/agent-setup.sh" "$root/tools/lib_disk_headroom.sh" \
    "$root/tools/lib_regenerable_ignored.sh" "$real/tools/"
cp "$root/.github/workflows/ci.yml" "$real/.github/workflows/ci.yml"
echo claude > "$real/CLAUDE.md"
git -C "$real" add -A && git -C "$real" commit -q -m real
git clone -q --bare "$real" "$work/real-origin.git"
git clone -q "$work/real-origin.git" "$work/real-main"
rout="$("$work/real-main/tools/agent-setup.sh" real feature/real 2>&1)"
check "this repository's gates list opens with /*" \
    has "$(sparse_line "$rout")" '/* !/docs/evidence/'
check "this repository's gates list keeps evidence SVGs" \
    has "$rout" '/docs/evidence/**/*.svg'

echo
echo "$checks checks, $failures failed"
[[ $failures -eq 0 ]]
