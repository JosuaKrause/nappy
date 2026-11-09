# The write guard, in full

What `.claude/hooks/github-write-guard.sh`, the hook that refuses a GitHub write outside an agent
identity, denies and what it asks the player about. **committing**'s "Who a commit and a pull
request are from" keeps the rules a session acts on; read this in a session where no identity can
work, or when a denial is not understood. The hook's own header comment is the exact list.

**When `status` reports the role not usable (not created yet, not installed on the repository,
or a cloud session — see `tools/agent-identity.py`'s own module docstring), the session never runs
the write under the player's own account on its own say-so.** Where no identity can work at all — a
Claude Code cloud session, or a machine with no identity directory — the guard below can ask the
player about an ordinary write instead of denying it: a local commit or history step (`git commit`,
`merge`, `rebase`, `pull`, `cherry-pick`, `revert`, `am`), a push of a branch, or a pull-request
write (`gh pr create`, `comment`, `edit`, `ready`) goes to them as a permission prompt
(frosty-pelican) for that one command, which only they can approve. Every other write is never asked
about, only denied — among them a push of a tag, of every branch or of a `*` pattern (a pushed `v*`
tag publishes the site), a push naming a shell expansion (`"$TAG"` can be a `v*` tag) or one the
guard cannot read to its end, a forced, deleting, mirroring or pruning push, a pull request's merge,
a release and a `gh issue` write — since a prompt is too easy to click through for any of them, and
for the last because the player wants an agent's issue writes to go through a script
(bouncy-heron 14) rather than a direct `gh issue` command; that script, `tools/inbox.py`, never
writes as the player, so where no identity can work an issue write is not made at all. **That asking
is off unless the player switches it on** with `NAPPY_ASK_FOR_PLAYER_WRITES=1` in the environment a
session starts with (a cloud environment's own variables, or the launching shell); unset, every
unwrapped write is denied (frosty-pelican). A session never sets or clears it for itself. Anything
the guard denies the session stops on and tells the player about, and Codex stops on every one of
them — except a direct `gh issue` write, which is made again through `tools/inbox.py` instead. A
`PreToolUse` Bash hook (`.claude/hooks/github-write-guard.sh`) makes this mechanical: it denies a
`git push`, a commit-making git verb, a GitHub-writing `gh` call, or one of the `tools/` scripts
that pushes or posts internally, in command position, unless the same command is wrapped in `run
<role> --`, so the rule holds even when a session forgets it. **A `gh issue` write it denies wrapped
or not, and an issue write through `gh api` the same way** (all but a comment, which a pull
request's own conversation shares), since an agent writes an issue only through `tools/inbox.py`,
whose own writes run in a process of their own that the hook never sees. **An approving review it
denies under every identity but a reviewer's**, and a review whose event it cannot read (a body from
`--input`, a `$(...)` among `gh pr review`'s words) counts as one, so a coder's or the
orchestrator's review names its event inline (`-f event=COMMENT`, `gh pr review --comment`) and
sends its body from a file (`-F body=@file`, `--body-file file`). **A git alias it reads as the
command it stands for**, asking git in the session's directory, and an alias set on the command line
(`git -c alias.*`) it denies whatever it says. A write named in a commit message or a PR body denies
like the write itself, so a message is written to a file and passed with `-F file` or `--body-file
file`, or given to a wrapped `git commit -F - <<'EOF'` that is the whole command, one of the three
shapes whose text the hook reads as text (**committing**, "Text handed to a write goes through a file", lists them). A read stays unguarded — the
hook's own header comment carries the current, exact list, rather than a second copy of it here that
can drift from it. **An admin action no bot identity can perform** — changing a repository ruleset,
a GitHub App's own permissions — **is the player's to do directly, in GitHub's own settings, never
something to wrap and retry.**
