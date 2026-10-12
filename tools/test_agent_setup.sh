#!/usr/bin/env bash
# Exercises tools/agent-setup.sh against a scratch clone: a throwaway "origin" (a bare repository)
# holding a few files, this repository's own .github/workflows/ci.yml (so the gates job's real
# sparse-checkout list is what the script reads) and the script itself, cloned to a main checkout
# the script then runs from.
#
#   tools/test_agent_setup.sh
#
# Asserts:
#   - --help/-h print usage and exit 0; an unknown flag, a missing value, a stray word and a bad
#     name are rejected before any worktree, branch or brief exists
#   - a setup makes the worktree on a new branch with no upstream, sparse by the gates job's list
#     (an evidence SVG kept, other evidence, docs/reference/ and docs/style-references/ left out),
#     writes the brief's header (branch, worktree, spawned, then a blank line) and prints a spawn
#     prompt naming the worktree, the brief and the contract
#   - a second setup of the same worktree, of the same branch and onto an existing brief is refused
#     and changes nothing
#   - --include brings a left-out folder back
#   - a headroom shortfall refuses before anything is made
#   - --agent appends one line per agent, newest last, and not the same id twice; --release adds
#     "cleanup: ready" once; both refuse a branch with no brief
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
check() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi; }
# $1 label  then a command that must fail
refuse() { local label="$1"; shift; if "$@" >/dev/null 2>&1; then fail "$label"; else ok "$label"; fi; }

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

seed="$work/seed"
mkdir -p "$seed/tools" "$seed/.github/workflows" "$seed/docs/evidence/run" "$seed/docs/reference" "$seed/docs/style-references" "$seed/src"
git init -q -b main "$seed"
cp "$root/tools/agent-setup.sh" "$root/tools/lib_disk_headroom.sh" "$seed/tools/"
cp "$root/.github/workflows/ci.yml" "$seed/.github/workflows/ci.yml"
echo claude > "$seed/CLAUDE.md"
echo code > "$seed/src/a.gd"
echo big > "$seed/docs/evidence/run/log.txt"
echo '<svg/>' > "$seed/docs/evidence/run/keep.svg"
echo photo > "$seed/docs/reference/photo.txt"
echo style > "$seed/docs/style-references/s.txt"
git -C "$seed" add -A && git -C "$seed" commit -q -m seed
git clone -q --bare "$seed" "$work/origin.git"
git clone -q "$work/origin.git" "$work/main"
main="$(cd "$work/main" && pwd -P)"
tool="$main/tools/agent-setup.sh"
briefs="$main/.claude/briefs"
state() { git -C "$main" worktree list --porcelain | grep -c '^worktree '; }

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
if [[ "$(state)" -eq 1 && ! -e "$briefs" && ! -e "$main/.claude/worktrees" ]]; then
    ok "rejections made no worktree and no brief"
else
    fail "rejections made no worktree and no brief"
fi

# -------------------------------------------------------------------------------------- setup ---
out="$("$tool" alpha feature/alpha 2>&1)"; status=$?
[[ $status -eq 0 ]] && ok "setup exits 0" || { fail "setup exits 0"; echo "$out" >&2; }
wt="$main/.claude/worktrees/alpha"
check "worktree is on the new branch" bash -c "[[ \"\$(git -C '$wt' branch --show-current)\" == feature/alpha ]]"
check "worktree starts at origin/main" bash -c "[[ \"\$(git -C '$wt' rev-parse HEAD)\" == \"\$(git -C '$main' rev-parse origin/main)\" ]]"
refuse "branch has no upstream" git -C "$wt" rev-parse --abbrev-ref feature/alpha@{upstream}
check "tracked code is present" test -f "$wt/src/a.gd"
check "evidence SVG kept by the gates list" test -f "$wt/docs/evidence/run/keep.svg"
check "other evidence left out" test ! -e "$wt/docs/evidence/run/log.txt"
check "docs/reference left out" test ! -e "$wt/docs/reference/photo.txt"
check "docs/style-references left out" test ! -e "$wt/docs/style-references/s.txt"
brief="$briefs/feature-alpha.md"
check "brief header has branch" grep -qx 'branch: feature/alpha' "$brief"
check "brief header has worktree" grep -qxF "worktree: $wt" "$brief"
check "brief header has spawned date" grep -qE '^spawned: [0-9]{4}-[0-9]{2}-[0-9]{2}$' "$brief"
check "brief header ends with a blank line" bash -c "[[ \"\$(sed -n 4p '$brief')\" == '' ]]"
check "prompt names the worktree" bash -c "grep -qF 'Your worktree is $wt' <<<\"\$1\"" _ "$out"
check "prompt names the brief" bash -c "grep -qF 'Read your brief at $brief' <<<\"\$1\"" _ "$out"
check "prompt names the contract" bash -c "grep -qF 'references/agent-contract.md' <<<\"\$1\"" _ "$out"

# ---------------------------------------------------------------------------------- refusals ---
cp "$brief" "$work/brief-before"
refuse "same worktree refused" "$tool" alpha feature/other
refuse "same branch refused" "$tool" beta feature/alpha
check "refusals left the brief alone" cmp -s "$brief" "$work/brief-before"
check "refusals made no other worktree" bash -c "[[ \"\$(git -C '$main' worktree list --porcelain | grep -c '^worktree ')\" -eq 2 ]]"
git -C "$main" push -q origin HEAD:refs/heads/feature/remote-only
refuse "existing remote branch refused" "$tool" gamma feature/remote-only
check "remote refusal made no worktree" test ! -e "$main/.claude/worktrees/gamma"
mkdir -p "$briefs" && echo "branch: feature/delta" > "$briefs/feature-delta.md"
refuse "existing brief refused" "$tool" delta feature/delta
check "brief refusal made no worktree" test ! -e "$main/.claude/worktrees/delta"
check "brief refusal made no branch" bash -c "! git -C '$main' show-ref --verify --quiet refs/heads/feature/delta"
NAPPY_HEADROOM_PEAK_MIB_WORKTREE_SPARSE=999999999 refuse "headroom shortfall refused" "$tool" eps feature/eps
check "headroom refusal made no worktree" test ! -e "$main/.claude/worktrees/eps"
check "headroom refusal made no brief" test ! -e "$briefs/feature-eps.md"

# ------------------------------------------------------------------------------------ include ---
"$tool" zeta feature/zeta --include docs/reference/ >/dev/null 2>&1
check "--include brings docs/reference back" test -f "$main/.claude/worktrees/zeta/docs/reference/photo.txt"
check "--include leaves docs/style-references out" test ! -e "$main/.claude/worktrees/zeta/docs/style-references/s.txt"

# ------------------------------------------------------------------- --agent and --release ---
"$tool" --agent feature/alpha id-one >/dev/null 2>&1
"$tool" --agent feature/alpha id-two >/dev/null 2>&1
"$tool" --agent feature/alpha id-two >/dev/null 2>&1
check "agent lines are one per id, newest last" bash -c "[[ \"\$(grep -n '^agent: ' '$brief' | tr '\n' ' ')\" == '4:agent: id-one 5:agent: id-two ' ]]"
check "agent lines stay in the header" bash -c "[[ \"\$(sed -n 6p '$brief')\" == '' ]]"
"$tool" --release feature/alpha >/dev/null 2>&1
"$tool" --release feature/alpha >/dev/null 2>&1
check "cleanup: ready added once" bash -c "[[ \"\$(grep -c '^cleanup: ready\$' '$brief')\" -eq 1 ]]"
check "the header still ends at the first blank line" bash -c "[[ \"\$(sed '/^\$/q' '$brief' | grep -c .)\" -eq 6 ]]"
refuse "--agent with no brief refused" "$tool" --agent feature/nothing id
refuse "--release with no brief refused" "$tool" --release feature/nothing

echo
echo "$checks checks, $failures failed"
[[ $failures -eq 0 ]]
