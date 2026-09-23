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
# Keyed on the agent as well as the session, the same way project-rules.sh is and for the same
# reason: `$session` for the main session, `$session-<agent_id>` for a sub-agent, so a sub-agent
# never shares -- or clears -- another agent's markers.
#
# Reads the hook JSON on stdin; prints hookSpecificOutput.additionalContext or nothing.

set -uo pipefail

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null)
agent=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
source=$(printf '%s' "$input" | jq -r '.source // empty' 2>/dev/null)

# Repo root: this script lives at <root>/.claude/hooks/
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
skills="$root/.claude/skills"
if [ -n "$agent" ]; then
	state="${TMPDIR:-/tmp}/claude-nappy-rules/$session-$agent"
else
	state="${TMPDIR:-/tmp}/claude-nappy-rules/$session"
fi
mkdir -p "$state" 2>/dev/null

# `source` is "startup" on a fresh session and "resume", "clear" or "compact" otherwise -- and on
# all three of those, whatever was in context, including this hook's own earlier injection, is
# gone or unreliable, but the marker files survive on disk. Left alone, a compacted session would
# never see the startup rule or any path rule again for the rest of its life. So on anything but
# "startup", clear this invocation's own marker directory before injecting -- this mirrors
# tools/codex-hooks.py's SessionStart/SubagentStart handling, which unlinks every skill marker
# under its own state dir before calling this same script. Keyed on $state (above), this only
# ever clears the session -- or, for a sub-agent, the one sub-agent -- that is actually restarting;
# a main session's compaction never touches a sub-agent's own directory and vice versa.
if [ -n "$source" ] && [ "$source" != "startup" ]; then
	rm -f "$state"/* 2>/dev/null
fi

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
