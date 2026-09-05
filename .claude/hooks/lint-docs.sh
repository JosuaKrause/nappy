#!/usr/bin/env bash
# Lints the governed doc that was just edited or written and hands the writer the hits.
#
# tools/lint.sh finds the sentence shapes that go stale on their own (a commit hash, a branch
# name, a check count, a ticked box, a status word in a heading). Running it only at commit
# time means the writer finds out a whole session late; this fires right after the Edit/Write
# that introduced the sentence, so the fix happens in the same turn.
#
# Reads the hook JSON on stdin; prints hookSpecificOutput.additionalContext (or nothing) and
# always exits 0 — a PostToolUse hook cannot block, the edit already happened.

set -uo pipefail

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$path" ] && exit 0

# Repo root: this script lives at <root>/.claude/hooks/
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# Only ever act on a file under this repo.
case "$path" in
	"$root"/*) ;;
	*) exit 0 ;;
esac

# History and primary sources are exempt — they are allowed to say what was true then.
case "$path" in
	"$root"/docs/DECISIONS.md|"$root"/docs/PLAYTEST-*.md|"$root"/docs/evidence/README.md)
		exit 0
		;;
esac

# The governed set: AGENTS.md, CLAUDE.md, .claude/skills/*/SKILL.md, README.md, docs/*.md.
governed=0
case "$path" in
	"$root"/AGENTS.md|"$root"/CLAUDE.md|"$root"/README.md|"$root"/.claude/skills/*/SKILL.md|"$root"/docs/*.md)
		governed=1
		;;
esac
[ "$governed" -eq 0 ] && exit 0

[ -x "$root/tools/lint.sh" ] || exit 0

lint_output=$("$root/tools/lint.sh" "$path" 2>&1)
lint_status=$?
[ "$lint_status" -eq 0 ] && exit 0

printf '%s' "$lint_output" | jq -Rs --arg p "$path" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("tools/lint.sh flagged what was just written to \($p) — fix these before moving on:\n" + .)
  }
}'
exit 0
