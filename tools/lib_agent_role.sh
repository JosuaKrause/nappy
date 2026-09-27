# Shared by the scripts that write to GitHub over a run that can outlive one installation
# token: tools/release.sh, tools/prune-merged.sh, tools/land-prs.sh and tools/update-pr.sh. An
# installation token lives one hour; tools/land-prs.sh alone can run 90 minutes per PR and take a
# list, so wrapping the whole script once (`run <role> -- tools/land-prs.sh ...`) can leave its
# later reads (its own wait loop's `gh pr view`/`gh pr checks`, a `git fetch`/`git pull`) and
# writes (`gh pr merge`, tools/prune-merged.sh's own branch delete) running on an expired token.
# Each of these scripts routes every one of its own GitHub calls, reads included, through
# `tools/agent-identity.py run "$NAPPY_AGENT_ROLE" --` instead, through this file's `agent_run`,
# so each one mints a fresh token of its own rather than living on the one the whole script may
# itself have been wrapped in.
#
# `run` already exports NAPPY_AGENT_ROLE for its own child process (see tools/agent-identity.py's
# own module docstring); this reads it back rather than taking the role as an argument, so a
# script invoked wrapped (`uv run python tools/agent-identity.py run <role> -- tools/land-prs.sh
# ...`) re-wraps its own calls as that same role automatically, with nothing else to pass down.
#
# **When NAPPY_AGENT_ROLE is unset, agent_run just runs the command directly, as the invoking
# user.** The player running one of these scripts by hand at their own terminal is not an agent --
# CLAUDE.md's mandatory-identity rule is "for each agent", and `.claude/hooks/github-write-guard.sh`
# is what makes an *agent's* own unwrapped call to one of these scripts fail; a human typing
# `tools/release.sh minor push` themself is not that call, and gets exactly what running it always
# got: their own `gh`/git login. See tools/update-pr.sh's own header for the corrected comment
# this used to carry the other way around.
#
# Not a script of its own -- `source` it (matching tools/lib_dev_flags.sh's own convention). Needs
# no PROJECT_DIR or root variable from the caller: it finds tools/agent-identity.py from its own
# location, which is where every caller keeps it too.
_agent_identity_py="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-identity.py"

# Runs "$@" through the caller's own agent identity, minting it a fresh installation token, when
# NAPPY_AGENT_ROLE is set; runs "$@" directly, unwrapped, when it is not.
agent_run() {
    if [ -n "${NAPPY_AGENT_ROLE:-}" ]; then
        uv run python "$_agent_identity_py" run "$NAPPY_AGENT_ROLE" -- "$@"
    else
        "$@"
    fi
}
