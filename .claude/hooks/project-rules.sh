#!/usr/bin/env bash
# Injects the project rules that govern the file about to be edited.
#
# A skill that has to be remembered is not a rule. This fires on the Edit/Write
# itself, maps the path to the skills in .claude/skills/ that govern it, and puts
# their text into context before the edit is made.
#
# Injected once per skill per session: the marker files under $STATE stop the same
# rules being repeated on every subsequent edit to the same area.
#
# A sub-agent's PreToolUse payload carries its own `agent_id`, but `session_id` is the
# *parent's* -- an orchestrator and every sub-agent it spawns share one session_id. Keyed on
# session_id alone, the first of them to touch an area silently used up that area's marker for
# all the others, and in two observed sessions only one of nine sub-agents that edited a .gd file
# ever received the godot rules. So the state directory is keyed on the agent too: plain
# `$session` for the main session (no agent_id in its payload), `$session-<agent_id>` for a
# sub-agent -- giving every sub-agent its own markers and so its own first-touch delivery of
# each area's rules.
#
# Reads the hook JSON on stdin; prints hookSpecificOutput.additionalContext or nothing.

set -uo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null)
agent=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)

# Repo root: this script lives at <root>/.claude/hooks/
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
skills="$root/.claude/skills"
if [ -n "$agent" ]; then
	state="${TMPDIR:-/tmp}/claude-nappy-rules/$session-$agent"
else
	state="${TMPDIR:-/tmp}/claude-nappy-rules/$session"
fi
mkdir -p "$state" 2>/dev/null

# One rule triggers on a tool rather than a path: spawning a sub-agent is an Agent/Task
# call with no file_path, and the orchestrating rules must arrive before the prompt is
# written, not after the agent comes back wrong.
if [ "$tool" = "Agent" ] || [ "$tool" = "Task" ]; then
	file="$skills/orchestrating/SKILL.md"
	if [ -f "$file" ] && [ ! -f "$state/orchestrating" ]; then
		: > "$state/orchestrating"
		printf '%s' "$(cat "$file")" | jq -Rs '{
		  hookSpecificOutput: {
		    hookEventName: "PreToolUse",
		    additionalContext: ("These project rules govern delegating work to sub-agents and are binding for this spawn. They are injected automatically, once per session.\n\n===== project rule: orchestrating =====\n" + .)
		  },
		  suppressOutput: true
		}'
	fi
	exit 0
fi

[ -z "$path" ] && exit 0

# The case patterns below match by substring (*/src/events/*, etc.), so without this
# check a file anywhere on disk under a same-named directory -- /tmp/elsewhere/src/events/x.gd --
# would receive this project's rules. Only a path under the computed repo root qualifies.
case "$path" in
	"$root"/*) ;;
	*) exit 0 ;;
esac

# Path -> skills that govern it. A file may match several; all of them fire.
wanted=()
case "$path" in
	*.svg)                    wanted+=(svg-art) ;;
esac
case "$path" in
	*/src/events/*)            wanted+=(events) ;;
esac
case "$path" in
	*/src/city/*)              wanted+=(city) ;;
esac
# StreetNetwork, ClosurePlanner, RouteTree, SealPlanner and RegionPlanner live here, and the
# `city` skill's description names them.
case "$path" in
	*/src/routes/*)            wanted+=(city) ;;
esac
case "$path" in
	*/src/crowd/*)             wanted+=(crowd-traffic) ;;
esac
# TrafficSignals and TrafficLight sit under src/city/ (so already get `city` above) and
# GroundShape sits at the top of src/ -- none of them match */src/crowd/*, but the
# `crowd-traffic` skill's description names TrafficSignals and GroundShape.tiles_under() is the
# crowd's footprint rule, so all three also need the crowd rules.
case "$path" in
	*/src/city/traffic_signals.gd|*/src/city/traffic_light.gd|*/src/ground_shape.gd) wanted+=(crowd-traffic) ;;
esac
case "$path" in
	*/src/ui/*|*/sprites.gd|*/palette.gd)   wanted+=(cues) ;;
esac
case "$path" in
	*/src/telemetry/*)         wanted+=(telemetry) ;;
esac
# The run-log autoload lives outside src/telemetry/.
case "$path" in
	*/src/autoload/telemetry.gd) wanted+=(telemetry) ;;
esac
case "$path" in
	*/art/illustrated/*)       wanted+=(illustrated-png) ;;
esac
case "$path" in
	*/docs/evidence/archive/rejected-graphics/*) wanted+=(rejected-graphics) ;;
esac
case "$path" in
	*/docs/evidence/archive/session-captures/*) wanted+=(session-captures) ;;
esac
# A backstop rather than the main door. Reference material arrives through `tools/reference.sh`,
# which is a Bash call with no `file_path` for this hook to see, so what this actually catches is
# somebody editing or hand-copying inside the folder — which is the case the rules most need to
# reach, since a hand-copied phone photo is the one that still has its GPS coordinates in it. The
# same backstop covers docs/style-references/, the second folder the same script writes into.
case "$path" in
	*/docs/reference/*|*/docs/style-references/*)        wanted+=(reference-photos) ;;
esac
case "$path" in
	*/autoload/tuning.gd)      wanted+=(balance) ;;
esac
case "$path" in
	*/tools/*.py|*/pyproject.toml|*/uv.lock|*/.python-version) wanted+=(python-tooling) ;;
esac
# Every command-line entry point, shell or Python, and the game's own dev-flag parser: help on
# --help/-h, and rejection of anything unknown before any work starts.
case "$path" in
	*/tools/*|*/src/dev/dev_flags.gd|*/src/dev/auto_screenshot.gd) wanted+=(cli-tools) ;;
esac
case "$path" in
	*/tests/*)                 wanted+=(verify) ;;
esac
# The queue (TODO.md's order, every entry's folder under docs/todo/), the review items and the
# playtests: what the player asked for, written down before anything is built.
case "$path" in
	*/docs/playtests/*.md|*/docs/TODO.md|*/docs/todo/*|*/docs/review/*) wanted+=(playtest-feedback) ;;
esac
case "$path" in
	*.gd)                      wanted+=(godot) ;;
esac
# A backstop, and it should never fire: session-rules.sh loads the orchestrating rules at the
# start of the session and writes the same marker, because *who implements this* is decided
# before any file is touched and both an Agent spawn and a first edit to src/ are already too
# late to ask it. This case exists only for a session that somehow started without that hook.
case "$path" in
	*/src/*|*/tests/*)         wanted+=(orchestrating) ;;
esac

[ ${#wanted[@]} -eq 0 ] && exit 0

out=""
for skill in "${wanted[@]}"; do
	file="$skills/$skill/SKILL.md"
	[ -f "$file" ] || continue
	[ -f "$state/$skill" ] && continue          # already injected this session
	: > "$state/$skill"
	out+=$'\n\n===== project rule: '"$skill"$' =====\n'
	out+=$(cat "$file")
done

[ -z "$out" ] && exit 0

printf '%s' "$out" | jq -Rs --arg p "$path" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: ("These project rules govern \($p) and are binding for this edit. They are injected automatically, once per area per session.\n" + .)
  },
  suppressOutput: true
}'
