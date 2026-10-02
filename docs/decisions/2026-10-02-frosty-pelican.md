# frosty-pelican — Where no identity can work, the write guard asks the player about an ordinary write · 2026-10-02 · not from an entry

**What it overturns.** [tall-egret, each agent posts on GitHub as an app of its own](2026-09-27-tall-egret.md)
records the player's choice, asked what an agent does when its identity is unusable, of "Stop
and tell me": `.claude/hooks/github-write-guard.sh` denied every unwrapped GitHub write, and a
session whose `tools/agent-identity.py status` said no role worked stopped there. In a Claude
Code cloud session no role ever works (the session's proxy refuses the API paths the manifest
flow needs, and there is no browser for its confirm page), so the guard made even a local
`git commit` impossible, and a cloud session could not commit or push its own work at all.

**What the player asked for.** In a cloud session that had built the rosy-chipmunk save fix and
could not commit it, the assistant offered two ways to let one write through safely: (A) the
guard answers "ask" instead of "deny", so Claude Code shows the player a permission prompt for
that exact command, or (B) the player types a grant line that a prompt hook turns into a
short-lived grant file. It recommended (A), since the player alone can answer a permission
prompt while a grant file is one the agent could write itself. The player chose:

> "Let's do A and make the codex version always refuse"

**What is built.** Where no identity can work — `CLAUDE_CODE_REMOTE=true`, or no identity
directory at `$NAPPY_AGENTS_DIR` or `~/.config/nappy-agents` — the guard answers `ask` for a
command whose every write is on `askable_reasons`: `git commit`, an ordinary `git push`, the local
history verbs (`merge`, `rebase`, `pull`, `cherry-pick`, `revert`, `am`), and `gh pr
create|comment|edit|ready` and `gh issue create|comment|edit`. Its reason tells the player the
command would go out under their own account and that the next one is asked about again. A push
that rewrites or deletes on the remote (`-f` or a short-flag cluster holding `f` or `d`,
`--force*`, `--delete`, `--mirror`, `--prune`, a `+` or `:` refspec) now reads as its own reason,
`git push --force`, and like a merge, any `gh api` write, a pushing `tools/` script, a reviewer's
push, a command too long to read and one the guard cannot parse, it stays denied wherever the
session runs. On a machine with identities set up nothing changes: an unwrapped write is denied
and the agent wraps it. `tools/codex-hooks.py` turns any guard answer but an allow into a deny,
so Codex never asks and keeps "stop and tell the player"; without that, an `ask` passed through
the adapter would have read as an allow.

**Rejected.** (B), the typed grant line: a grant file is something the agent could create itself,
which the guard could only discourage, and whether a message the player sends while the agent is
mid-turn reaches a prompt hook is not documented. Pushing through the GitHub connector instead of
git was used once for the rosy-chipmunk branch, on the player's say-so, and is not a route: the
connector takes whole files, so a two-line change to a 160 KB file means retyping all of it.

**Verified.** `tools/test_rules_hooks.sh` (the guard's cases now run pinned to a machine with
identities, plus each ask and deny case above under a cloud session and under no identity
directory) and `tools/pycheck.sh` (with a Codex test that a cloud session's or an unconfigured
machine's ask reaches Codex as a deny) pass; `tools/codex-hooks.py` still runs under the host's
Python 3.11. Whether a Claude Code cloud session shows the prompt was checked in the session that
built it, by committing this change through it.
