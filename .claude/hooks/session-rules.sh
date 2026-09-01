#!/usr/bin/env bash
# Injects the rules that have to be true before the first tool call of a session.
#
# The path-triggered hook (project-rules.sh) answers "what governs this file",
# and it can only fire once a file is already being touched. Some rules are about
# what happens *before* that -- who should be doing the work at all -- and for those
# the first edit is already too late. Those load here, at the start.
#
# Keep this list very short. Everything injected here is paid for in every session,
# whether or not it turns out to be relevant, which is exactly the cost the
# path-triggered hook exists to avoid.
#
# Reads the hook JSON on stdin; prints hookSpecificOutput.additionalContext or nothing.

set -uo pipefail

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null)

# Repo root: this script lives at <root>/.claude/hooks/
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
skills="$root/.claude/skills"
state="${TMPDIR:-/tmp}/claude-nappy-rules/$session"
mkdir -p "$state" 2>/dev/null

# Loaded at the start of every session, in this order.
at_the_start=(orchestrating)

out=""
for skill in "${at_the_start[@]}"; do
	file="$skills/$skill/SKILL.md"
	[ -f "$file" ] || continue
	[ -f "$state/$skill" ] && continue
	# The same marker project-rules.sh uses, so nothing injects one of these twice in
	# a session however it is next triggered.
	: > "$state/$skill"
	out+=$'\n\n===== project rule: '"$skill"$' =====\n'
	out+=$(cat "$file")
done

[ -z "$out" ] && exit 0

printf '%s' "$out" | jq -Rs '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("These project rules are binding for this whole session. They are injected automatically at the start, because they govern decisions taken before the first tool call.\n" + .)
  },
  suppressOutput: true
}'
