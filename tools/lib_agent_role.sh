# Shared by the scripts that write to GitHub over a run that can outlive one installation
# token: tools/release.sh, tools/prune-merged.sh, tools/land-prs.sh and tools/update-pr.sh. An
# installation token lives one hour; tools/land-prs.sh alone can run 90 minutes per PR and take a
# list, so wrapping the whole script once (`run <role> -- tools/land-prs.sh ...`) can leave its
# later gh pr merge/auto-merge calls and tools/prune-merged.sh's own branch delete running on an
# expired token. Each of these scripts wraps every one of its own GitHub writes in
# `tools/agent-identity.py run "$NAPPY_AGENT_ROLE" --` instead, through this file's `agent_run`, so
# each write mints a fresh token of its own.
#
# `run` already exports NAPPY_AGENT_ROLE for its own child process (see tools/agent-identity.py's
# own module docstring); this reads it back rather than taking the role as an argument, so a
# script invoked wrapped (`uv run python tools/agent-identity.py run <role> -- tools/land-prs.sh
# ...`) re-wraps its own writes as that same role automatically, with nothing else to pass down.
#
# Not a script of its own -- `source` it (matching tools/lib_dev_flags.sh's own convention). Needs
# no PROJECT_DIR or root variable from the caller: it finds tools/agent-identity.py from its own
# location, which is where every caller keeps it too.
_agent_identity_py="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-identity.py"

# Runs "$@" through the caller's own agent identity, minting it a fresh installation token.
# Fails loudly, before running anything, if NAPPY_AGENT_ROLE is unset or empty, rather than
# falling back to a bare call that would post as whoever's account is logged into gh/git --
# a GitHub write is never made without an agent identity.
agent_run() {
    if [ -z "${NAPPY_AGENT_ROLE:-}" ]; then
        echo "$(basename "$0"): NAPPY_AGENT_ROLE is not set -- run this script through" \
            "'uv run python tools/agent-identity.py run <role> -- $(basename "$0") ...'," \
            "which sets it; refusing to run '$*' with no agent identity" >&2
        exit 1
    fi
    uv run python "$_agent_identity_py" run "$NAPPY_AGENT_ROLE" -- "$@"
}
