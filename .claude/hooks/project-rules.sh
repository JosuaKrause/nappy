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
# Reads the hook JSON on stdin; prints hookSpecificOutput.additionalContext or nothing.

set -uo pipefail

input=$(cat)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null)
[ -z "$path" ] && exit 0

# Repo root: this script lives at <root>/.claude/hooks/
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
skills="$root/.claude/skills"
state="${TMPDIR:-/tmp}/claude-nappy-rules/$session"
mkdir -p "$state" 2>/dev/null

# Path -> skills that govern it. A file may match several; all of them fire.
wanted=()
case "$path" in
	*/src/events/*)            wanted+=(events) ;;
esac
case "$path" in
	*/src/city/*)              wanted+=(city) ;;
esac
case "$path" in
	*/src/crowd/*)             wanted+=(crowd-traffic) ;;
esac
case "$path" in
	*/src/ui/*|*/sprites.gd|*/palette.gd)   wanted+=(cues) ;;
esac
case "$path" in
	*/src/telemetry/*)         wanted+=(telemetry) ;;
esac
case "$path" in
	*/autoload/tuning.gd)      wanted+=(balance) ;;
esac
case "$path" in
	*/tests/*)                 wanted+=(verify) ;;
esac
case "$path" in
	*/docs/PLAYTEST-*.md|*/docs/TODO.md)    wanted+=(feedback) ;;
esac
case "$path" in
	*.gd)                      wanted+=(godot) ;;
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
