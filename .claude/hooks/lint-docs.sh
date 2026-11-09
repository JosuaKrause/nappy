#!/usr/bin/env bash
# Lints the governed doc that was just edited or written and hands the writer the hits, in
# whichever checkout of this repository the file is: the main one or an agent's worktree.
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

# The checkout the edited file belongs to, and the file's path inside it. An agent works in a
# worktree under <main>/.claude/worktrees/, while the hook that runs is the main checkout's (the
# harness starts it from the session's project directory), so the root is taken from the file and
# never from where this script lives: the doc is matched against its own checkout's layout and
# linted by its own checkout's tools/lint.sh, which is the version its branch will be judged by.
# Git names the path inside the checkout (`--show-prefix`), so a symlinked directory on the way
# (macOS's /tmp and /var) cannot make the two disagree.
here=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
dir=$(dirname "$path")
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root=""
if [ -n "$root" ]; then
	# Only this repository's checkouts: the tree this script lives in is itself a checkout, and
	# the file's checkout shares its git directory with it, or is that one.
	here_top=$(git -C "$here" rev-parse --show-toplevel 2>/dev/null) || here_top=""
	mine=$(git -C "$here" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || mine=""
	theirs=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || theirs=""
	if [ "$here_top" != "$(cd "$here" && pwd -P)" ] || [ -z "$mine" ] || [ "$mine" != "$theirs" ]; then
		root=""
	else
		rel="$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)$(basename "$path")"
	fi
fi
if [ -z "$root" ]; then
	# No git answer (a copy of the tree that is not a checkout, or no git on the PATH): the file
	# counts only when it sits under the tree this script lives in.
	case "$path" in
		"$here"/*) root="$here"; rel="${path#"$here"/}" ;;
		*) exit 0 ;;
	esac
fi

# History is exempt — it is allowed to say what was true then.
case "$rel" in
	docs/DECISIONS.md|docs/evidence/README.md)
		exit 0
		;;
esac

# The governed set: AGENTS.md, CLAUDE.md, every Markdown file under .claude/skills/ (each SKILL.md
# and the reference files beside it, at any depth: a `case` pattern's `*` matches "/" too),
# README.md, docs/*.md, the queue's files (docs/todo/<entry>/*.md) and the review items
# (docs/review/*.md) -- the set tools/lint.sh scans by default (see its own file-collecting loop)
# -- plus a record under docs/decisions/ and a playtest, which lint.sh checks for a name used twice
# and nothing else. Because that `*` matches "/", a bare `docs/*.md` also matches
# `docs/evidence/x/README.md` and every other doc buried under a subdirectory, among them the
# evidence READMEs under docs/evidence/, which legitimately record branch and commit provenance
# (a bracket-expression prefix like `[!/]*` does not help: the `[!/]` restricts only the one
# character before the `*`). So a path under docs/ is sorted by what is left after the "docs/"
# prefix comes off: only a direct child of docs/ has no "/" left in it.
governed=0
case "$rel" in
	AGENTS.md|CLAUDE.md|README.md|.claude/skills/*.md)
		governed=1
		;;
	docs/*.md)
		sub="${rel#docs/}"
		case "$sub" in
			todo/*/*/*) ;;       # deeper than an entry's own files -- not governed
			todo/*/*|review/*|decisions/*|playtests/*)
				# The queue and the review list are governed like any doc. A record and a playtest
				# are history and primary sources, which tools/lint.sh spares the sentence rules,
				# but a name they take is still checked against every other name.
				case "$sub" in
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

lint_output=$("$root/tools/lint.sh" "$root/$rel" 2>&1)
lint_status=$?
[ "$lint_status" -eq 0 ] && exit 0

# The harness places a hook's context inline only up to 10,000 characters and cuts anything longer
# to its opening, so a doc with many hits is answered with the first of them and where the rest
# are, all of it well under that size.
LINT_OUTPUT_MAX=6000
if [ "$(printf '%s' "$lint_output" | wc -c)" -gt "$LINT_OUTPUT_MAX" ]; then
	lint_output="$(printf '%s' "$lint_output" | head -c "$LINT_OUTPUT_MAX" | sed '$d')
... (more hits than fit here: run tools/lint.sh $rel in $root for all of them)"
fi

printf '%s' "$lint_output" | jq -Rs --arg p "$path" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("tools/lint.sh flagged what was just written to \($p) — fix these before moving on:\n" + .)
  }
}'
exit 0
