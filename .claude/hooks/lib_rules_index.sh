#!/usr/bin/env bash
# Sourced by project-rules.sh and session-rules.sh: the one-line index entry that stands for a
# project skill, and how the two hooks tell a caller that reads an index from one that does not.
#
# The hooks name the skills and never print their text. The harness places a hook's output in
# context only up to 10,000 characters; anything longer is saved to a file and replaced by its
# first 2,000 characters and a path nobody is asked to open, and most skills are longer than that
# alone. An entry is a line, so the whole index stays under 2,000 bytes whatever it names and
# arrives whole: the name, the path, the size (what the read costs) and the opening clause of the
# skill's own description.

# The longest description clause an entry prints, in characters.
RULES_INDEX_DESCRIPTION_MAX=110

# $1 the skills directory  $2 a skill's name. Prints the skill's entry, one line:
#   - events (.claude/skills/events/SKILL.md, 31 KB): Rules for adding or changing an event
# The description is the frontmatter's `description:` up to its first dash clause or sentence end,
# cut at RULES_INDEX_DESCRIPTION_MAX; a skill file without one gets an entry without it.
rules_index_entry() {
	local file="$1/$2/SKILL.md" bytes kb desc
	bytes=$(wc -c < "$file" 2>/dev/null | tr -d ' ')
	kb=$(( (${bytes:-0} + 512) / 1024 ))
	[ "$kb" -lt 1 ] && kb=1
	desc=$(awk '
		NR == 1 && $0 != "---" { exit }
		NR > 1 && $0 == "---" { exit }
		/^description:/ { sub(/^description:[ \t]*/, ""); print; exit }
	' "$file" 2>/dev/null)
	desc="${desc%% — *}"
	desc="${desc%%. *}"
	desc="${desc%.}"
	if [ "${#desc}" -gt "$RULES_INDEX_DESCRIPTION_MAX" ]; then
		desc="${desc:0:$((RULES_INDEX_DESCRIPTION_MAX - 3))}..."
	fi
	printf -- '- %s (.claude/skills/%s/SKILL.md, %s KB)%s\n' "$2" "$2" "$kb" "${desc:+: $desc}"
}

# $1 the payload's session_id. True when the caller is the Codex adapter (tools/codex-hooks.py),
# which renames every session `codex-<hash>` before it runs a hook. The adapter is frozen with the
# rest of Codex support: it passes on a hook's `additionalContext` and nothing else, so it cannot
# deliver a refusal, and its tests expect the skills' text. For that caller the hooks keep printing
# the text as context; every other caller gets the index.
rules_caller_wants_text() {
	case "$1" in
		codex-*) return 0 ;;
		*) return 1 ;;
	esac
}
