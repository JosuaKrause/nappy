**The GitHub write guard lets an issue write through the inbox script, and still denies an agent's
direct issue command** (statement 14: "if it goes through a script it's safe we just need to get
it working once -- an agent shouldn't use gh issue directly"). `.claude/hooks/github-write-guard.sh`
denies every `gh` write verb unless the command runs through `tools/agent-identity.py run <role>
--`; the inbox and capture scripts are the one sanctioned way an agent writes an issue, run under
that wrapper, and an issue write typed by an agent as a bare `gh` command, wrapped or not, stays
denied. The hook's own header comment lists what counts as a write, and changes with it.

The guard also denies a read, or a file write, when a write command's words appear only as text:
a `grep` whose search pattern names the issue command, or a heredoc whose prose names it. A
command word inside a quoted argument or a heredoc body that is not run is not in command
position, and the guard stops treating it as one where it can tell.

The Codex adapter, `tools/codex-hooks.py`, runs the same hook on Codex's Bash calls; this item
checks whether the adapter or `tools/test_codex_hooks.py` needs to change and changes them in the
same PR if so (`CLAUDE.md`, "Codex integration"). `tools/test_rules_hooks.sh` gains a case for
each new allowed and denied shape.
