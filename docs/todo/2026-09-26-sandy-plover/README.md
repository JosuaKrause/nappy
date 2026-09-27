priority: later

# sandy-plover — The git-grep guard's deny message fits in one argument on Linux · filed 2026-09-26

Found by PR #377's last review (https://github.com/JosuaKrause/nappy/pull/377#pullrequestreview-5327490027),
not blocking, and merged with it. `.claude/hooks/git-grep-guard.sh` builds its deny message with
`jq -n --arg reason "$reason"`, and the reason quotes the flagged text. The 32 KB length bound counts
characters, not bytes, so a flagged text of about 32,000 four-byte characters makes a reason past
Linux's 128 KB limit on one argument: `jq` fails, nothing reaches stdout, and the hook lets the
command through. Only on Linux (CI, a Linux Codex, a cloud session), and only for a deliberately
built command.
