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

# History is exempt — it is allowed to say what was true then.
case "$path" in
	"$root"/docs/DECISIONS.md|"$root"/docs/evidence/README.md)
		exit 0
		;;
esac

# The governed set: AGENTS.md, CLAUDE.md, .claude/skills/*/SKILL.md, README.md, docs/*.md, the
# queue's files (docs/todo/<entry>/*.md) and the review items (docs/review/*.md) -- the set
# tools/lint.sh scans by default (see its own file-collecting loop) -- plus a record under
# docs/decisions/ and a playtest, which lint.sh checks for a name used twice and nothing else. A bash
# `case` pattern's `*` matches "/" same as any other character (a bracket-expression prefix like
# `[!/]*` does not fix this -- the `[!/]` restricts only the one character before the `*`, and
# the `*` itself still matches anything), so a bare `docs/*.md` also matched
# `docs/evidence/x/README.md` and every other doc buried under a subdirectory -- flagging the
# evidence READMEs under docs/evidence/, which legitimately record branch and commit provenance.
# Checked instead with a parameter-expansion prefix strip: only a direct child of docs/ has no
# "/" left in what remains after the "docs/" prefix comes off.
governed=0
case "$path" in
	"$root"/AGENTS.md|"$root"/CLAUDE.md|"$root"/README.md|"$root"/.claude/skills/*/SKILL.md)
		governed=1
		;;
	"$root"/docs/*.md)
		rel="${path#"$root"/docs/}"
		case "$rel" in
			todo/*/*/*) ;;       # deeper than an entry's own files -- not governed
			todo/*/*|review/*|decisions/*|playtests/*)
				# The queue and the review list are governed like any doc. A record and a playtest
				# are history and primary sources, which tools/lint.sh spares the sentence rules,
				# but a name they take is still checked against every other name.
				case "$rel" in
					review/*/*|decisions/*/*|playtests/*/*) ;;
					*) governed=1 ;;
				esac
				;;
			*/*) ;;              # any other subdirectory of docs/ -- not governed
			*)   governed=1 ;;
		esac
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
