#!/usr/bin/env bash
# Exercises tools/lib_agent_role.sh's `agent_run` -- the helper tools/release.sh,
# tools/prune-merged.sh, tools/land-prs.sh and tools/update-pr.sh each route every one of their
# own GitHub calls, reads included, through, so a token expiring partway through a long run does
# not fail a later call (see those scripts' own headers, and
# docs/decisions/2026-09-27-tall-egret.md).
#
#   tools/test_lib_agent_role.sh
#
# Asserts, against `agent_run` directly, with a stub `uv` on PATH recording its own argv:
#   - NAPPY_AGENT_ROLE unset -> the wrapped command runs directly, unwrapped, as the invoking user
#     -- a human running one of these scripts by hand at their own terminal is not an agent, and
#     gets exactly what running it always got
#   - NAPPY_AGENT_ROLE set -> the stub `uv` is invoked as
#     `uv run python <path-to-agent-identity.py> run "$NAPPY_AGENT_ROLE" -- <the command>`,
#     never the bare command directly
#   - NAPPY_AGENT_ROLE=claude-orchestrator -> re-wrapped as that same role, and the real
#     agent-identity.py's run parser accepts it (stops at "not configured", not "invalid choice")
#
# Then, end to end through tools/prune-merged.sh with a stubbed `gh` (reporting a MERGED PR
# matching the local tip) and the same stub `uv`, against a real throwaway git repo standing in
# for GitHub (a bare "origin" the branch is actually pushed to and deleted from), because a stub
# only for `uv` would not catch a write that skipped `agent_run` and called `git`/`gh` directly:
#   - NAPPY_AGENT_ROLE unset -> the remote branch is still deleted, calling gh/git directly (the
#     player's own login), never through the stub `uv`
#   - NAPPY_AGENT_ROLE set -> the remote branch is deleted, and the stub `uv` recorded both the
#     read (`gh pr view`) and the delete running through `agent-identity.py run <role> --`, not a
#     bare `gh`/`git push`
#
# Bash 3.2-safe (no associative arrays, no globstar) -- the same reason the rest of tools/ stays
# this side of bash 4; see tools/lint.sh's own header.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

usage() {
    cat <<'EOF'
usage: tools/test_lib_agent_role.sh [--help|-h]

Exercises tools/lib_agent_role.sh's agent_run (runs unwrapped with NAPPY_AGENT_ROLE unset, and the
exact re-wrap it runs when it is set) and, end to end, tools/prune-merged.sh's own gh pr view read
and remote branch delete through it, against a stub uv/gh and a real throwaway git repo.
Takes no arguments besides --help/-h.

  tools/test_lib_agent_role.sh
EOF
}

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
        *)
            echo "unknown option: $arg" >&2
            echo >&2
            usage >&2
            exit 2
            ;;
    esac
done

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

checks=0
failures=0
fail() {
    echo "FAIL $1" >&2
    failures=$((failures + 1))
}
ok() {
    echo "ok   $1"
}

# A stub `uv` on PATH: for `uv run python <path> run <role> -- <cmd...>`, appends the full argv
# (one word per line, a blank line ending the record) to $UV_LOG and then really execs <cmd...>,
# so a test that needs the write to actually happen (the prune-merged.sh one below) still sees it
# happen -- only the identity-minting is stubbed, not the git/gh call it wraps.
stub_bin="$work_dir/bin"
mkdir -p "$stub_bin"
UV_LOG="$work_dir/uv-log"
export UV_LOG
: > "$UV_LOG"
cat > "$stub_bin/uv" <<'STUB'
#!/usr/bin/env bash
set -uo pipefail
# uv's own argv: run [--quiet] [--project DIR] python <agent-identity.py path> run <role> -- <cmd...>
# A real uv without --quiet/--project can write its own diagnostic noise to stderr (a
# VIRTUAL_ENV-does-not-match warning, a first-run "Creating virtual environment..." notice) --
# this stub reproduces exactly that failure mode when either flag is missing, so a test capturing
# combined stdout+stderr the way tools/land-prs.sh's own `agent_run gh pr view ... 2>&1` does would
# see it and fail if agent_run ever stopped passing them.
has_quiet=0
has_project=0
for arg in "$@"; do
    [ "$arg" = "--quiet" ] && has_quiet=1
    [ "$arg" = "--project" ] && has_project=1
done
if [ "$has_quiet" -eq 0 ] || [ "$has_project" -eq 0 ]; then
    echo "warning: a real uv would print noise here without --quiet/--project" >&2
fi
# Skips uv's own flags rather than assuming a fixed position, so a flag agent_run adds or drops
# does not need a matching change here.
shift 1  # drop uv's own "run"
while [ "$1" != "python" ]; do shift; done
shift 1  # drop "python"
shift 1  # drop the agent-identity.py path -- the shape is asserted by the words around it, not the path
shift 1  # drop agent-identity.py's own "run"
role="$1"; shift
shift 1  # drop the literal "--"
{
    echo "role=$role"
    printf '%s\n' "$@"
    echo
} >> "$UV_LOG"
exec "$@"
STUB
chmod +x "$stub_bin/uv"
export PATH="$stub_bin:$PATH"

# ------------------------------------------------------------------- agent_run itself -----------
marker="$work_dir/ran"
rm -f "$marker"
unset NAPPY_AGENT_ROLE
bash -c '
    source "'"$root"'/tools/lib_agent_role.sh"
    agent_run touch "'"$marker"'"
'
rc=$?
checks=$((checks + 1))
if [ "$rc" -eq 0 ] && [ -e "$marker" ]; then
    ok "agent_run with NAPPY_AGENT_ROLE unset runs the command directly, unwrapped"
else
    fail "agent_run with NAPPY_AGENT_ROLE unset: rc=$rc, marker exists: $([ -e "$marker" ] && echo yes || echo no)"
fi
checks=$((checks + 1))
logged="$(cat "$UV_LOG")"
if [ -z "$logged" ]; then
    ok "agent_run with NAPPY_AGENT_ROLE unset never calls the stub uv"
else
    fail "agent_run with NAPPY_AGENT_ROLE unset called uv anyway: $logged"
fi

rm -f "$marker"
: > "$UV_LOG"
bash -c '
    source "'"$root"'/tools/lib_agent_role.sh"
    export NAPPY_AGENT_ROLE=claude-coder
    agent_run touch "'"$marker"'"
'
checks=$((checks + 1))
if [ -e "$marker" ]; then
    ok "agent_run with NAPPY_AGENT_ROLE set runs the wrapped command"
else
    fail "agent_run with NAPPY_AGENT_ROLE set did not run the wrapped command"
fi
checks=$((checks + 1))
logged="$(cat "$UV_LOG")"
if grep -q '^role=claude-coder$' <<<"$logged" && grep -qx "touch" <<<"$logged"; then
    ok "agent_run re-wraps through agent-identity.py run claude-coder -- touch ..."
else
    fail "agent_run's own re-wrap did not look right: $logged"
fi

# claude-orchestrator, the role a docs-only pull request's and an issue's writes go out as, is
# passed through the same way: agent_run names whatever role it was wrapped in, never a fixed one.
rm -f "$marker"
: > "$UV_LOG"
bash -c '
    source "'"$root"'/tools/lib_agent_role.sh"
    export NAPPY_AGENT_ROLE=claude-orchestrator
    agent_run touch "'"$marker"'"
'
checks=$((checks + 1))
logged="$(cat "$UV_LOG")"
if [ -e "$marker" ] && grep -q '^role=claude-orchestrator$' <<<"$logged"; then
    ok "agent_run re-wraps through agent-identity.py run claude-orchestrator -- touch ..."
else
    fail "agent_run as claude-orchestrator: marker exists: $([ -e "$marker" ] && echo yes || echo no), log: $logged"
fi

# And the real agent-identity.py's run parser accepts the role agent_run hands it: with no config
# for it, `run` stops at "not configured" (exit 1), not at argparse's "invalid choice" (exit 2).
# The stub `uv` shadows the real one here, so the interpreter is the checkout's own .venv when it
# exists and the host's python3 otherwise (CI runs this before it installs uv).
empty_agents="$work_dir/no-agents"
mkdir -p "$empty_agents"
real_python="$root/.venv/bin/python"
[ -x "$real_python" ] || real_python=python3
checks=$((checks + 1))
real_out="$(NAPPY_AGENTS_DIR="$empty_agents" "$real_python" "$root/tools/agent-identity.py" \
    run --repo O/R claude-orchestrator -- true 2>&1)"
real_rc=$?
if [ "$real_rc" -eq 1 ] && grep -q 'create claude-orchestrator' <<<"$real_out"; then
    ok "agent-identity.py run accepts claude-orchestrator (stops at not configured)"
else
    fail "agent-identity.py run claude-orchestrator: rc=$real_rc: $real_out"
fi

# A caller that captures agent_run's combined stdout+stderr (tools/land-prs.sh's own
# `agent_run gh pr view ... 2>&1`, parsed as JSON) must not see uv's own diagnostic noise mixed in
# -- the stub uv reproduces that noise whenever --quiet/--project are missing from its own argv.
checks=$((checks + 1))
combined="$(bash -c '
    source "'"$root"'/tools/lib_agent_role.sh"
    export NAPPY_AGENT_ROLE=claude-coder
    agent_run echo "{\"ok\": true}"
' 2>&1)"
if [ "$combined" = '{"ok": true}' ]; then
    ok "agent_run passes --quiet --project, so a caller's combined stdout+stderr stays clean"
else
    fail "agent_run's own uv call let noise through: $combined"
fi

# --------------------------------------------------------- end to end: tools/prune-merged.sh -----
# A real throwaway git repo standing in for GitHub: a bare "origin", a clone with a merged-looking
# branch pushed to it, so prune-merged.sh's own remote branch delete is a real `git push --delete`
# against a real remote -- proving the write actually happens through agent_run, not merely that
# agent_run itself is wired right in isolation above.
origin_bare="$work_dir/origin.git"
git init --quiet --bare "$origin_bare"
clone_dir="$work_dir/clone"
git clone --quiet "$origin_bare" "$clone_dir" 2>/dev/null
(
    cd "$clone_dir" || exit 1
    git config user.email test@example.com
    git config user.name Test
    git commit --quiet --allow-empty -m base
    git push --quiet origin HEAD:refs/heads/main
    git checkout --quiet -b feature/probe
    git commit --quiet --allow-empty -m probe
    git push --quiet origin feature/probe
)
merged_head="$(git -C "$clone_dir" rev-parse feature/probe)"

# A stub `gh` reporting that PR that branch's own merged head, matching the live tip -- the exact
# shape prune-merged.sh's own `gh pr view --json state,headRefOid,number` reads. Called either
# directly (NAPPY_AGENT_ROLE unset) or through the stub uv above (set) -- both land here.
cat > "$stub_bin/gh" <<STUB
#!/usr/bin/env bash
if [ "\$1" = pr ] && [ "\$2" = view ]; then
    echo "MERGED $merged_head 999"
    exit 0
fi
if [ "\$1" = pr ] && [ "\$2" = list ]; then
    echo 0
    exit 0
fi
echo "unexpected gh call: \$*" >&2
exit 1
STUB
chmod +x "$stub_bin/gh"

run_prune() {
    (
        cd "$clone_dir" || exit 1
        git checkout --quiet main
        "$root/tools/prune-merged.sh" feature/probe
    )
}

# prune-merged.sh deletes the local branch before it ever reaches the remote delete agent_run
# wraps, so restoring for a second run means recreating both the local branch (feature/probe
# already deleted by the first run) and the remote one (deleted by either run, since both now
# actually delete it -- NAPPY_AGENT_ROLE unset runs the delete directly rather than refusing).
restore_branch() {
    git -C "$clone_dir" branch -f feature/probe "$merged_head" >/dev/null 2>&1
    (cd "$clone_dir" && git push --quiet origin "$merged_head:refs/heads/feature/probe" --force) 2>/dev/null \
        || git -C "$origin_bare" update-ref "refs/heads/feature/probe" "$merged_head"
}

unset NAPPY_AGENT_ROLE
: > "$UV_LOG"
run_prune >"$work_dir/prune-out" 2>&1
prune_rc=$?
checks=$((checks + 1))
if ! git -C "$origin_bare" show-ref --verify --quiet refs/heads/feature/probe; then
    ok "prune-merged.sh with NAPPY_AGENT_ROLE unset still deletes the remote branch (rc=$prune_rc)"
else
    fail "prune-merged.sh with NAPPY_AGENT_ROLE unset did not delete the remote branch (rc=$prune_rc): $(cat "$work_dir/prune-out")"
fi
checks=$((checks + 1))
logged="$(cat "$UV_LOG")"
if [ -z "$logged" ]; then
    ok "prune-merged.sh with NAPPY_AGENT_ROLE unset never calls the stub uv -- gh/git ran directly"
else
    fail "prune-merged.sh with NAPPY_AGENT_ROLE unset called uv anyway: $logged"
fi
rm -f "$work_dir/prune-out"

restore_branch
: > "$UV_LOG"
export NAPPY_AGENT_ROLE=claude-coder
run_prune >"$work_dir/prune-out" 2>&1
prune_rc=$?
checks=$((checks + 1))
if ! git -C "$origin_bare" show-ref --verify --quiet refs/heads/feature/probe; then
    ok "prune-merged.sh with NAPPY_AGENT_ROLE set deletes the remote branch (rc=$prune_rc)"
else
    fail "prune-merged.sh with NAPPY_AGENT_ROLE set did not delete the remote branch (rc=$prune_rc): $(cat "$work_dir/prune-out")"
fi
checks=$((checks + 1))
logged="$(cat "$UV_LOG")"
if grep -q '^role=claude-coder$' <<<"$logged"; then
    ok "the read (gh pr view) and the delete both ran through agent-identity.py run claude-coder --"
else
    fail "the calls did not go through agent_run: $logged"
fi
checks=$((checks + 1))
if grep -qx "view" <<<"$logged"; then
    ok "gh pr view is wrapped too, not only the write"
else
    fail "gh pr view did not go through agent_run: $logged"
fi
checks=$((checks + 1))
if grep -q -- '--delete' <<<"$logged"; then
    ok "the delete ran through agent-identity.py run claude-coder --, not a bare git push"
else
    fail "the delete did not go through agent_run: $logged"
fi
rm -f "$work_dir/prune-out"
unset NAPPY_AGENT_ROLE

echo
echo "$checks checks, $failures failures"
if [ "$failures" -gt 0 ]; then
    exit 1
fi
