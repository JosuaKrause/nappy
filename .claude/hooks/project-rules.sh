#!/usr/bin/env bash
# Names the project skills that govern the file about to be edited, and refuses the first edit of
# an area until they have been read.
#
# A skill that has to be remembered is not a rule. This fires on the Edit/Write itself, maps the
# path to the skills in .claude/skills/ that govern it, and answers with their index: each skill's
# name, path, size and one-line description (lib_rules_index.sh says why an index and never the
# text). The first edit of an area is denied with that index as the reason, which the harness
# shows to the session; the same edit made again passes. Reading is the step between the two, and
# the retry is how a session says it has read: nothing watches the reads themselves, since a hook
# that judged them could refuse an edit for good on a skill that reached the session another way.
#
# Named once per skill per session: the marker files under $STATE record what has been named. A
# marker written by a refusal holds the time of it, and an edit that arrives within
# $BATCH_SECONDS of that time is refused as well, in one line: the calls of one message run back
# to back, so without it the first of them would be refused and the rest would land unread. The
# window is a clock standing in for "the same message", and it is wrong both ways, which is why
# it is short. A session that had read the skills before and makes the edit again at once can
# land inside it, so that refusal says both things it can be, and that the edit is made again.
# And an edit of the area after the window passes whether or not anything was read: that is the
# mechanism's limit, since nothing watches the reads. A marker whose time is in the future (the
# clock stepped back) counts as old: the edit passes and the marker is emptied, so that it
# cannot refuse an edit later, when the clock reaches it.
#
# A sub-agent's PreToolUse payload carries its own `agent_id`, but `session_id` is the
# *parent's* -- an orchestrator and every sub-agent it spawns share one session_id. Keyed on
# session_id alone, the first of them to touch an area silently used up that area's marker for
# all the others, and in two observed sessions only one of nine sub-agents that edited a .gd file
# ever received the godot rules. So the state directory is keyed on the agent too: plain
# `$session` for the main session (no agent_id in its payload), `$session-<agent_id>` for a
# sub-agent -- giving every sub-agent its own markers and so its own refusal at its own first
# edit of each area. A second area in the same session is refused the same way, naming only the
# skills not named before. After a compaction session-rules.sh clears the main session's
# markers, so each of its areas is refused once more. A sub-agent's are not cleared: the hooks
# documentation gives a sub-agent SubagentStart, when it is spawned, and describes SessionStart
# as a session's, and no hook here is wired to SubagentStart or to a compaction event. So a
# sub-agent whose context is compacted is not refused a second time, which is a known limit.
#
# Spawning a sub-agent (the Agent/Task tool) gets the index as context beside the call and is
# never refused: a spawn carries a whole brief, and a refusal would have it written twice.
#
# Reads the hook JSON on stdin; prints a PreToolUse permissionDecision "deny" with the index as
# its reason, hookSpecificOutput.additionalContext, or nothing.

set -uo pipefail
# No word below is ever meant as a file name pattern: the table's globs are matched as text.
set -f

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
session=$(printf '%s' "$input" | jq -r '.session_id // "nosession"' 2>/dev/null)
agent=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)

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

# How long after a refusal another edit of the same area counts as part of the same message. The
# hook answers in well under a second and the next call's hook starts when the refusal returns,
# so two seconds cover a message's calls and catch few edits made again by a session that had
# already read.
BATCH_SECONDS=2

# What governs what, one row per line of CLAUDE.md's path table ("The rules load themselves"),
# in the same order and the same words: tools/test_rules_hooks.sh compares the two row for row.
# Left of "=>" are the row's paths, right of it the skills it brings. A path is written from the
# checkout's root; one with no "/" is a file's name at any depth; "**" stands for any folders and
# "*" for any run of characters, a "/" among them, as in a `case` pattern (so `tools/*.py` reaches
# a Python file in a folder below tools/ too). `tool:<Name>` is a tool call and not a path.
#
# Only files an edit tool can write have a row. A PNG, a recording or a sound file is written by
# a tool or copied in, which this hook never sees, so the tools that write them name their skill
# themselves (tools/reference.sh, tools/synthesize-sfx.py, tools/shot.sh).
# rules-table-begin
rows=(
	"src/events/** => events"
	"src/city/** src/routes/** => city"
	"src/crowd/** src/city/traffic_signals.gd src/city/traffic_light.gd src/ground_shape.gd => crowd-traffic"
	"src/ui/** sprites.gd palette.gd src/events/views/event_look.gd src/crowd/crowd_agent.gd src/player/stroller.gd src/events/warning_board.gd => cues"
	"src/telemetry/** src/autoload/telemetry.gd => telemetry"
	"src/autoload/tuning.gd src/events/event_catalogue.gd src/events/event_scheduler.gd src/crowd/crowd_lanes.gd src/player/baby.gd src/city/city.gd src/field.gd src/events/dawn_phases/ruled_roadblock_ground.gd src/events/ruled_location_ground.gd src/events/dawn_phases/dawn_masts.gd src/events/dawn_phases/dawn_spoilers.gd => balance"
	"tools/*.py pyproject.toml uv.lock .python-version => python-tooling"
	"tools/synthesize-sfx.py => sound-effects"
	"tools/reference.sh tools/reference.py docs/reference/** docs/style-references/** => reference-photos"
	"tools/** src/dev/dev_flags.gd src/dev/auto_screenshot.gd => cli-tools"
	"tests/** => verify writing-tests"
	"docs/playtests/*.md docs/TODO.md docs/todo/** docs/review/** => playtest-feedback"
	"art/illustrated/** => illustrated-png"
	"assets/atlases/membership.json => svg-art illustrated-png"
	"docs/evidence/archive/rejected-graphics/** => rejected-graphics"
	"docs/evidence/** => verify session-captures"
	".github/workflows/** => verify"
	".claude/settings.json docs/decisions/** => committing"
	"*.gd *.tscn *.gdshader project.godot => godot"
	"src/**/*.gd => designing-classes"
	"*.svg => svg-art"
	"src/** tests/** => orchestrating"
	"tool:Agent tool:Task => orchestrating"
)
# rules-table-end
# Why a row is there, where its paths do not say it:
# - src/routes/ holds StreetNetwork, ClosurePlanner, RouteTree, SealPlanner and RegionPlanner,
#   which the city skill's description names.
# - TrafficSignals and TrafficLight sit under src/city/ and GroundShape at the top of src/; the
#   crowd-traffic skill's description names TrafficSignals, and GroundShape.tiles_under() is the
#   crowd's footprint rule.
# - The four files named after palette.gd draw the cues: the mark and its color, the car's caret,
#   the exclamation mark over the stroller, and the warning board that raises it.
# - The ten files besides tuning.gd in the balance row hold the numbers the balance skill's
#   description names outside Tuning: the catalogue's caps, the views' shares, the crowd's
#   busyness, the baby's excitement, the city's decay multipliers and the field's falloff. Four
#   of them are event files the dawn phases and the ruled ground hold numbers in: the roadblocks'
#   close-by distance, the mouse's pile weights, the curfew day and the park spoilers' numbers.
# - assets/atlases/membership.json is the text file both kinds of artwork are registered in.
# - docs/evidence/ holds experiment evidence (verify: its method, provenance and retention) and
#   captures (session-captures: where a frame is kept and what it may be said to prove).
# - A workflow under .github/workflows/ decides what the `test` check means, which verify owns.
# - committing owns the two things in its row: the allow lines in the settings file and why no
#   other is added, and how a decision record is named and filed.
# - The hook scripts under .claude/hooks/ have no row. No skill says what a change to one owes
#   (CLAUDE.md does: its cases in tools/test_rules_hooks.sh, and this table kept in step with
#   CLAUDE.md's), and a row that names a skill which does not cover its path costs a read and
#   delivers no rule.
# - The orchestrating row for src/ and tests/ is a backstop for a session that started without
#   session-rules.sh, which names that skill at the start and writes the same marker. It is the
#   orchestrating session's skill, so that row never applies to a sub-agent (an `agent_id` in the
#   payload); a sub-agent that itself spawns one is named it by the tool row.

# The subject the rows are matched against: the tool, for a spawn, or the file's path inside its
# checkout. Only a path under the computed repo root qualifies, so a same-named directory
# elsewhere on disk -- /tmp/elsewhere/src/events/x.gd -- gets none of this project's rules; an
# agent's worktree sits under the root, at .claude/worktrees/<name>/, and its files are governed
# like the main checkout's.
#
# The path is first read as text, with its "." and ".." parts and doubled slashes taken out, so
# that <root>/docs/../src/events/a.gd is named what <root>/src/events/a.gd is. Nothing is looked
# up on disk: the file need not exist yet, and a path that is not absolute is nobody's.
normalized() {
	local part out="" IFS=/
	for part in $1; do
		case "$part" in
			''|.) ;;
			..) out="${out%/*}" ;;
			*) out="$out/$part" ;;
		esac
	done
	printf '%s' "${out:-/}"
}

rel=""
spawn=0
if [ "$tool" = "Agent" ] || [ "$tool" = "Task" ]; then
	spawn=1
else
	[ -z "$path" ] && exit 0
	case "$path" in
		/*) path=$(normalized "$path") ;;
	esac
	case "$path" in
		"$root"/*) rel="${path#"$root"/}" ;;
		*) exit 0 ;;
	esac
	case "$rel" in
		.claude/worktrees/*/*) rel="${rel#.claude/worktrees/*/}" ;;
	esac
fi

# True if the glob $1 matches the subject.
matches() {
	local glob="$1" pattern
	case "$glob" in
		tool:*) [ "$spawn" -eq 1 ] && [ "${glob#tool:}" = "$tool" ]; return ;;
	esac
	[ "$spawn" -eq 1 ] && return 1
	# "**/" may stand for no folder at all, so it goes; what is left of "**" is a `case` "*".
	pattern="${glob//\*\*\//}"
	pattern="${pattern//\*\*/*}"
	# shellcheck disable=SC2254  # the pattern is meant to be one
	case "$glob" in
		*/*)
			case "$rel" in
				$pattern) return 0 ;;
			esac
			;;
		*)
			case "/$rel" in
				*/$pattern) return 0 ;;
			esac
			;;
	esac
	return 1
}

# The skills that govern the subject, in the table's order, each once.
wanted=" "
for row in "${rows[@]}"; do
	globs="${row% => *}"
	row_skills="${row#* => }"
	hit=0
	for glob in $globs; do
		if matches "$glob"; then
			hit=1
			break
		fi
	done
	[ "$hit" -eq 0 ] && continue
	for skill in $row_skills; do
		if [ "$skill" = "orchestrating" ] && [ "$spawn" -eq 0 ] && [ -n "$agent" ]; then
			continue
		fi
		case "$wanted" in
			*" $skill "*) ;;
			*) wanted="$wanted$skill " ;;
		esac
	done
done

# Of those, the ones this session has not been named yet, and whether any was named by a refusal
# less than $BATCH_SECONDS ago. Only a time from zero up to the window counts: a marker stamped
# in the future is old, and is emptied.
now=$(date +%s)
fresh=""
recent=0
for skill in $wanted; do
	[ -f "$skills/$skill/SKILL.md" ] || continue
	if [ -f "$state/$skill" ]; then
		refused_at=$(cat "$state/$skill" 2>/dev/null)
		case "$refused_at" in
			''|*[!0-9]*) ;;
			*)
				since=$((now - 10#$refused_at))
				if [ "$since" -lt 0 ]; then
					: 2>/dev/null > "$state/$skill"
				elif [ "$since" -lt "$BATCH_SECONDS" ]; then
					recent=1
				fi
				;;
		esac
		continue
	fi
	fresh="$fresh$skill "
done

# The Codex adapter gets the text of the fresh skills as context, as it always has.
if rules_caller_wants_text "$session"; then
	[ -z "$fresh" ] && exit 0
	out=""
	for skill in $fresh; do
		: > "$state/$skill"
		out+=$'\n\n===== project rule: '"$skill"$' =====\n'
		out+=$(cat "$skills/$skill/SKILL.md")
	done
	printf '%s' "$out" | jq -Rs --arg p "${path:-a sub-agent spawn}" '{
	  hookSpecificOutput: {
	    hookEventName: "PreToolUse",
	    additionalContext: ("These project rules govern \($p) and are binding for it. They are injected automatically, once per area per session.\n" + .)
	  },
	  suppressOutput: true
	}'
	exit 0
fi

how="Read each one whole (the Skill tool by its name, or Read on its path under $root), unless you have read it whole in this context"

index=""
for skill in $fresh; do
	index+="$(rules_index_entry "$skills" "$skill")"$'\n'
done

if [ "$spawn" -eq 1 ]; then
	[ -z "$fresh" ] && exit 0
	for skill in $fresh; do
		: > "$state/$skill"
	done
	printf 'Spawning a sub-agent is governed by the project skill below. Its text is not put into context for you. %s, before the next spawn, and check this brief against it.\n\n%s' \
		"$how" "$index" | jq -Rs '{
	  hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: . },
	  suppressOutput: true
	}'
	exit 0
fi

deny() {
	jq -Rs '{
	  hookSpecificOutput: {
	    hookEventName: "PreToolUse",
	    permissionDecision: "deny",
	    permissionDecisionReason: .
	  },
	  suppressOutput: true
	}'
}

if [ -n "$fresh" ]; then
	# A refusal is only given where it can be remembered. Where the marker cannot be written (no
	# writable state directory), refusing would refuse every edit for good, so the index goes
	# beside the edit as context and the edit is let through.
	stamped=1
	for skill in $fresh; do
		printf '%s\n' "$now" 2>/dev/null > "$state/$skill" || stamped=0
	done
	if [ "$stamped" -eq 0 ]; then
		printf '%s is governed by the project skills below, and their text is not put into context for you. %s, before the next edit there.\n\n%s' \
			"$rel" "$how" "$index" | jq -Rs '{
		  hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: . },
		  suppressOutput: true
		}'
		exit 0
	fi
	printf 'Refused once, so that the rules are read before the edit. %s is governed by the project skills below, and their text is not put into context for you. %s. Then make this edit again: it passes. (One made within %s seconds of this refusal is refused as a call of the same message.)\n\n%s' \
		"$rel" "$how" "$BATCH_SECONDS" "$index" | deny
	exit 0
fi

if [ "$recent" -eq 1 ]; then
	# True of both edits that can land here: one of the same message as the refused edit, which
	# nothing was read for, and one made again at once by a session that had read already.
	printf 'Refused, because a refusal naming the skills that govern %s was given less than %s seconds ago: this edit was sent in the same message as the one refused then, or it was made again within %s seconds of the refusal. If you have not read the skills that refusal names, read each one whole first; if you have read the skills named, make it again.\n' \
		"$rel" "$BATCH_SECONDS" "$BATCH_SECONDS" | deny
	exit 0
fi

exit 0
