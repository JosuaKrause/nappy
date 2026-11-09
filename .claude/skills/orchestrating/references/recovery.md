# Recovering agents

The steps behind two of **orchestrating**'s rules: an agent that died mid-task is replaced in its
own worktree, and after a limit or an outage the pause's length decides whether each agent is nudged
or replaced. Read it before replacing an agent, and at the start of a session that finds agents
stopped.

## An agent that died mid-task is replaced in its own worktree

A usage limit or an API error kills the agent and leaves every edit it made, usually uncommitted.
Past the cache window (woolly-finch 22), start the fresh agent in the dead agent's worktree. The
brief it needs comes from `.claude/briefs/<branch>.md` — the file the orchestrator wrote before
spawning, kept current by every amendment sent since; the previous session's transcript under
`~/.claude/projects/` is only the fallback when no such file exists. The replacement agent's prompt
is "read `.claude/briefs/<file>`, then what changed: …", plus what the orchestrator verified on
disk: which files are modified, what was never run, and where the dead agent stopped, read from its
own transcript's last tool calls. Its first two steps are to commit the inherited work as it stands
and to merge `origin/main`. Say plainly that nothing inherited has been reviewed, and that it may
not even compile.

**Starting the replacement includes updating ownership.** Right after spawning it, run
`tools/agent-setup.sh --agent <branch> <new id>` to append `agent: <new id>` to the worktree's
brief, and write the `worktree:` line if it is missing. If no brief exists, create one with the
header and a pointer to where the original brief is. `agent-status.sh` reads the last `agent:`
line, so skipping this step leaves the worktree credited to the dead agent.

**Before inheriting anything, compare the worktree with its own branch on the remote.** Another
session can pick the same branch up while the agent is dead: the remote then carries pushed
commits the worktree never saw, and committing the inherited edits on top of the stale head
forks the branch. Fetch, and count `git rev-list HEAD..@{u}`. If it is not zero, diff the
inherited edits against what was pushed; where the pushed commits already do the same work,
save the inherited diff under `$TMPDIR`, discard it, fast-forward, and brief the fresh agent
from the pushed state instead.

## An agent a restart stopped is resumed while it is warm

**An agent a restart of the session stopped is resumed, not rebriefed, while it is warm.**
`SendMessage` addressed to the id on the newest `agent:` line of its brief resumes it with its
context, and its worktree still holds its uncommitted work. `tools/agent-status.sh` prints that id
per worktree only when it finds the agent's transcript, and reports warm or cold. A cold one is
replaced as step 4 below says, with a fresh agent briefed from the brief and the worktree's state.

## After a limit or an outage

**A limit or an outage stops every agent at once, and the pause's length decides what happens
next.** The player usually tries to hand the session off before a limit hits, so the next one starts
fresh at the reset, but not every limit is seen coming (woolly-finch 26).

1. **Run `tools/agent-status.sh` before touching anything.** It covers every worktree's branch,
   uncommitted files, how far it is ahead of and behind its own upstream (another session may have
   pushed to it), its PR's CI state, its brief file, and its credited agent's warm/cold verdict in
   one pass — across this checkout and any other local clone of the repo it is told about or finds
   from Codex's own session history, each block naming which one it is in, with a warning when the
   same branch is checked out in more than one. What it cannot show is where an agent stopped
   inside an item — for that, read its transcript's last tool calls, the file `agent-status.sh`
   named.
2. **Take the pause's kind from the player.** If they have not said, it is long when the
   agent's last request is older than the cache window less five minutes (**orchestrating**, "A
   finished agent is not resumed after it has gone cold"), and brief otherwise.
3. **Brief pause: nudge each agent with `SendMessage`**: the limit is over, what its worktree
   and branch now hold if that moved, and continue. The cache is warm, so the agent's own
   context is the cheapest brief there is. **This changes no ownership** — the agent named on the
   brief is still the one working, so append nothing. **In Codex, check the live agent status:**
   `send_message` only queues a message and does not start an idle or interrupted agent's turn.
   Resume a warm idle or interrupted agent with `followup_task`; use `send_message` for a running
   agent. A queued reply is not evidence that work resumed.
4. **Long pause: replace each agent** in its own worktree, as the first section says, with a brief
   updated to what step 1 found, and its ownership updated the moment the replacement's id is
   known. Never resume a cold one.
5. **Tell the player what was found per agent and which way each went**, before waiting on any
   of them.

## Proposed, not asked for

- **That an agent a restart stopped is resumed, not rebriefed, while it is warm** is the filer's
  proposal, open to the player's correction. The player's words are that a cold agent is not
  resumed (woolly-finch 5) and that state is kept where a fresh session finds it (inbox #986 in
  brisk-pelican).
