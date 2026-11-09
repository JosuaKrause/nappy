#!/usr/bin/env bash
# Names the skills whose rules have to be read before the first tool call of a session.
#
# The path-triggered hook (project-rules.sh) answers "what governs this file",
# and it can only fire once a file is already being touched. Some rules are about
# what happens *before* that -- who should be doing the work at all -- and for those
# the first edit is already too late. Those are named here, at the start: the index entry of
# each (lib_rules_index.sh says why an index and never the text), with the instruction to read it
# whole. A SessionStart hook can add context and cannot refuse anything, so this one only names.
#
# Keep this list very short. Everything named here is to be read in every session,
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
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../.." && pwd)
skills="$root/.claude/skills"
# shellcheck source=.claude/hooks/lib_rules_index.sh
source "$here/lib_rules_index.sh"
if [ -n "$agent" ]; then
	state="${TMPDIR:-/tmp}/claude-nappy-rules/$session-$agent"
else
	state="${TMPDIR:-/tmp}/claude-nappy-rules/$session"
fi
mkdir -p "$state" 2>/dev/null

# `source` is "startup" on a fresh session and "resume", "clear", "compact" or "fork" otherwise --
# and on all of those, whatever was in context, a skill read earlier included, is gone or
# unreliable, but the marker files survive on disk. Left alone, a compacted session would
# never be named the startup rule or any path rule again for the rest of its life. So on anything
# but "startup", clear this invocation's own marker directory before naming -- this mirrors
# tools/codex-hooks.py's SessionStart/SubagentStart handling, which unlinks every skill marker
# under its own state dir before calling this same script. Keyed on $state (above), this only
# ever clears the session -- or, for a sub-agent, the one sub-agent -- that is actually restarting;
# a main session's compaction never touches a sub-agent's own directory and vice versa.
if [ -n "$source" ] && [ "$source" != "startup" ]; then
	rm -f "$state"/* 2>/dev/null
fi

# Named at the start of every session, in this order.
at_the_start=(orchestrating)

fresh=""
for skill in "${at_the_start[@]}"; do
	[ -f "$skills/$skill/SKILL.md" ] || continue
	[ -f "$state/$skill" ] && continue
	# The same marker project-rules.sh uses, so nothing names one of these twice in
	# a session however it is next triggered. It is left empty: a marker holds a time only when
	# a refusal wrote it.
	: > "$state/$skill"
	fresh="$fresh$skill "
done

[ -z "$fresh" ] && exit 0

# The Codex adapter gets the text as context, as it always has.
if rules_caller_wants_text "$session"; then
	out=""
	for skill in $fresh; do
		out+=$'\n\n===== project rule: '"$skill"$' =====\n'
		out+=$(cat "$skills/$skill/SKILL.md")
	done
	printf '%s' "$out" | jq -Rs '{
	  hookSpecificOutput: {
	    hookEventName: "SessionStart",
	    additionalContext: ("These project rules are binding for this whole session. They are injected automatically at the start, because they govern decisions taken before the first tool call.\n" + .)
	  },
	  suppressOutput: true
	}'
	exit 0
fi

index=""
for skill in $fresh; do
	index+="$(rules_index_entry "$skills" "$skill")"$'\n'
done

printf 'These project skills govern this whole session, because they decide things that are settled before the first tool call. Their text is not put into context for you: read each one whole now, before anything else (the Skill tool by its name, or Read on its path under %s).\n\n%s\nThe skills that govern a file are named the same way at the first edit there, which is refused once so that they are read before the edit is made again.\n' \
	"$root" "$index" | jq -Rs '{
  hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: . },
  suppressOutput: true
}'
