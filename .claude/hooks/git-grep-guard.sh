#!/usr/bin/env bash
# Denies a `git grep` that can grow without bound.
#
# On 2026-09-26 a sub-agent's `git grep -i "...\|..."` over docs/ (about 900 MB of PNG/JPEG/MP4
# evidence, plus JSON traces with 100 KB lines) ran with no tree given, no `-I`, and no text-only
# pathspec, and a second command repeated the shape in a `for` loop over several refs -- both from
# the main checkout, both against Apple's `git` (2.54, Apple Git-157), which runs the regex over
# every blob unless told not to. The unified log shows the kernel killing `git` at about 80 GB, six
# times in a row -- once per loop iteration -- then a watchdog-timeout panic on a 16 GB Mac.
# Measured afterwards, every run capped and polled for peak RSS rather than let run uncapped (see
# the pull request that added this file for the full table): the same pattern without `-I` climbed
# past 2.7 GB and was still climbing at a 2-second cap, on the *working tree* alone, no tree-ish
# needed; `-F` (fixed string) climbed the same way -- the driver is the absence of `-I`, not regex
# backtracking. Either `-I` (skip binary files) or a pathspec restricted to known text extensions
# keeps it bounded and fast regardless of `-F`, how many trees are named, or which tree: measured
# between 15 MB and 916 MB, finishing in under two seconds every time either guard was present.
#
# So: deny a `git grep` invocation -- however it is spelled (`git grep`, `git -C <dir> grep`,
# `git --no-pager grep`) and wherever it sits (a loop body, after &&/;/|, inside `$(...)`) -- unless
# it carries `-I` or a `--` pathspec made only of known-text-extension globs. Everything else,
# including a bare mention of the words ("echo git grep", a commit message, `rg "git grep"`),
# passes silently: those never tokenize as a standalone `git` word followed by `grep`, because a
# quoted span becomes one opaque token in the scan below.
#
# Reads the hook JSON on stdin. Denies via hookSpecificOutput.permissionDecision (PreToolUse "deny"
# JSON, see the pull request description for the doc citation confirming this shape and that
# PreToolUse fires for a sub-agent's own tool calls too -- a sub-agent is what ran the command
# above). Bash 3.2-safe, jq and bash only -- no external tokenizer, no rg, no python.

set -uo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool" = "Bash" ] || exit 0
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$command" ] && exit 0

# ---------------------------------------------------------------------------- tokenizer --------
# Splits $1 into one token per output line: a run of non-space, non-metacharacter text is one
# token; a single- or double-quoted span (its quote marks stripped, backslash-escapes inside
# double quotes resolved) is one token whatever it contains, including spaces and the literal
# words "git" or "grep" -- which is what keeps a quoted mention ("echo git grep", a commit
# message, `rg "git grep"`) from ever tokenizing as the bare word `git` followed by `grep`; and
# each of `; & | ( ) `` is its own one-character token, so a real invocation is found wherever it
# sits (loop body, after a separator, inside `$(...)` -- which reaches the scan as `$`, `(`, then
# the command's own words).
#
# Tokens are printed NUL-separated (a token may legitimately contain a newline) and read back with
# `read -d ''`, which is bash-3.2-safe.
tokenize() {
	local s="$1" i=0 n=${#1} c cur="" have=0 in_transparent=0 close subst
	while ((i < n)); do
		c="${s:i:1}"
		case "$c" in
		' ' | $'\t' | $'\n')
			if [ "$have" = 1 ]; then printf '%s\0' "$cur"; cur=""; have=0; fi
			i=$((i + 1))
			;;
		';' | '&' | '|' | '(' | ')' | '`')
			if [ "$have" = 1 ]; then printf '%s\0' "$cur"; cur=""; have=0; fi
			printf '%s\0' "$c"
			i=$((i + 1))
			;;
		"'")
			have=1
			i=$((i + 1))
			while ((i < n)) && [ "${s:i:1}" != "'" ]; do
				cur+="${s:i:1}"
				i=$((i + 1))
			done
			((i < n)) && i=$((i + 1))
			;;
		'"')
			# A double-quoted span still runs command substitution inside it, so a span
			# containing `$(` or a backtick is transparent, not opaque: skip only the
			# quote marks themselves (tracked with in_transparent, since the closing mark
			# must be recognised as a close rather than scanned again as a fresh open) and
			# let the interior tokenize normally, so an invocation inside
			# `"$(git grep ...)"` is still found. A span with neither is slurped whole, as
			# before -- what keeps a literal mention ("echo git grep") from ever splitting
			# into the two bare words `git` and `grep`.
			if [ "$in_transparent" = 1 ]; then
				in_transparent=0
				i=$((i + 1))
			else
				close=$((i + 1))
				subst=0
				while ((close < n)) && [ "${s:close:1}" != '"' ]; do
					if [ "${s:close:1}" = '\' ] && ((close + 1 < n)); then
						close=$((close + 2))
					else
						if [ "${s:close:1}" = '`' ]; then subst=1; fi
						if [ "${s:close:1}" = '$' ] && ((close + 1 < n)) && [ "${s:close+1:1}" = '(' ]; then subst=1; fi
						close=$((close + 1))
					fi
				done
				if [ "$subst" = 1 ]; then
					in_transparent=1
					i=$((i + 1))
				else
					have=1
					i=$((i + 1))
					while ((i < n)) && [ "${s:i:1}" != '"' ]; do
						if [ "${s:i:1}" = '\' ] && ((i + 1 < n)); then
							cur+="${s:i+1:1}"
							i=$((i + 2))
						else
							cur+="${s:i:1}"
							i=$((i + 1))
						fi
					done
					((i < n)) && i=$((i + 1))
				fi
			fi
			;;
		*)
			have=1
			cur+="$c"
			i=$((i + 1))
			;;
		esac
	done
	[ "$have" = 1 ] && printf '%s\0' "$cur"
}

toks=()
while IFS= read -r -d '' tok; do
	toks+=("$tok")
done < <(tokenize "$command")

n=${#toks[@]}

# A word that legitimately preceded a fresh command, so `git` right after it is a real invocation
# start rather than a plain argument glued onto whatever came before.
is_boundary() {
	case "$1" in
	';' | '&' | '|' | '(' | '`' | do | then | else | '{' | '!') return 0 ;;
	*) return 1 ;;
	esac
}

# A `-I` flag, standalone or bundled into another short-option cluster (`-nI`, `-Iin`, ...); never
# matches a `--long` option, since the character right after the leading `-` there is another `-`.
has_dash_I() {
	case "$1" in
	-[!-]*)
		case "$1" in
		*I*) return 0 ;;
		esac
		;;
	esac
	return 1
}

# A pathspec argument restricted to a known text extension -- the shapes the fix examples in this
# file's header and the pull request actually use (`*.md`, `*.gd`, `*.sh`, ...). Not exhaustive on
# purpose: an unrecognised extension falls through to "not text-restricted", which asks for `-I`
# instead, the safe default.
is_text_glob() {
	case "$1" in
	*.md | *.gd | *.sh | *.py | *.json | *.toml | *.txt | *.cfg | *.ini | *.yml | *.yaml | \
		*.csv | *.svg | *.html | *.htm | *.css | *.js | *.ts | *.xml | *.rs | *.go | *.c | *.h | \
		*.cpp | *.hpp | *.java | *.rb | *.pl | *.tres | *.tscn | *.gdshader | *.glsl | *.cs) return 0 ;;
	*) return 1 ;;
	esac
}

findings=()
i=0
while [ "$i" -lt "$n" ]; do
	if [ "${toks[$i]}" = "git" ] && { [ "$i" -eq 0 ] || is_boundary "${toks[$((i - 1))]}"; }; then
		j=$((i + 1))
		# Optional `-C <dir>` and `--no-pager`, in either order, either or both present.
		while [ "$j" -lt "$n" ]; do
			case "${toks[$j]}" in
			-C)
				j=$((j + 2)) # -C and its argument
				;;
			--no-pager)
				j=$((j + 1))
				;;
			*) break ;;
			esac
		done
		if [ "$j" -lt "$n" ] && [ "${toks[$j]}" = "grep" ]; then
			# The invocation's own tail: everything from `grep` up to the next unquoted
			# separator (already its own token) or the end of the token stream.
			k=$((j + 1))
			while [ "$k" -lt "$n" ]; do
				case "${toks[$k]}" in
				';' | '&' | '|' | ')' | '`') break ;;
				esac
				k=$((k + 1))
			done
			# tail = toks[j+1 .. k-1]
			has_I=0
			dashdash=-1
			t=$((j + 1))
			while [ "$t" -lt "$k" ]; do
				if [ "$dashdash" -lt 0 ]; then
					if [ "${toks[$t]}" = "--" ]; then
						dashdash=$t
					elif has_dash_I "${toks[$t]}"; then
						has_I=1
					fi
				fi
				t=$((t + 1))
			done
			text_only=0
			if [ "$dashdash" -ge 0 ] && [ $((dashdash + 1)) -lt "$k" ]; then
				text_only=1
				t=$((dashdash + 1))
				while [ "$t" -lt "$k" ]; do
					if ! is_text_glob "${toks[$t]}"; then
						text_only=0
						break
					fi
					t=$((t + 1))
				done
			fi
			if [ "$has_I" = 0 ] && [ "$text_only" = 0 ]; then
				tail=""
				t=$j
				while [ "$t" -lt "$k" ]; do
					tail="$tail ${toks[$t]}"
					t=$((t + 1))
				done
				findings+=("git$tail")
			fi
			i=$k
			continue
		fi
	fi
	i=$((i + 1))
done

[ "${#findings[@]}" -eq 0 ] && exit 0

reason="This git grep has neither -I nor a --pathspec restricted to text extensions. Measured on \
this repo's ~900 MB docs/ (binaries included), that shape grows past 2.7 GB and keeps climbing \
rather than finish. Rewrite it: add -I (skip binary files), restrict the pathspec to text globs \
(e.g. -- '*.md' '*.gd' '*.sh'), or use rg on the checkout instead of git grep. Flagged: ${findings[*]}"

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
exit 0
