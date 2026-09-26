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
# So: deny a `git grep` invocation -- however it is spelled (`git grep`, any global option before
# `grep`, such as `-C <dir>`, `-c name=val`, `--git-dir=...`, `--no-pager`, `-P`) and wherever it
# sits (a loop body, after &&/;/| or an unquoted newline, inside `$(...)`) -- unless it carries
# `-I` or a `--` pathspec made only of known-text-extension globs. Everything else, including a
# bare mention of the words ("echo git grep", a commit message, `rg "git grep"`) and a heredoc body
# that happens to mention them (never executed, so never scanned), passes silently: those never
# tokenize as a standalone `git` word followed by `grep`, because a quoted span becomes one opaque
# token in the scan below and a heredoc body is skipped outright.
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
# message, `rg "git grep"`) from ever tokenizing as the bare word `git` followed by `grep`; each of
# `; & | ( ) `` and an unquoted newline is its own one-character token (a newline separates
# commands exactly like `;`, unless it starts a heredoc body -- see below), so a real invocation is
# found wherever it sits (loop body, after a separator, on its own line, inside `$(...)` -- which
# reaches the scan as `$`, `(`, then the command's own words).
#
# A `<<[-]WORD` (or quoted `<<'WORD'`/`<<"WORD"`) heredoc operator queues WORD; at the next
# unquoted newline, every subsequent line up to and including one that -- after stripping leading
# tabs, for `<<-` -- is exactly WORD is body text, not a command, and is skipped rather than
# tokenized, so a heredoc body that happens to mention "git grep" is never scanned (it is never
# executed either). A bare `<<<` here-string has no such body and is left alone.
#
# Tokens are printed NUL-separated (a token may legitimately contain a newline) and read back with
# `read -d ''`, which is bash-3.2-safe.
tokenize() {
	local s="$1" i=0 n=${#1} c cur="" have=0 in_transparent=0 close subst
	local heredoc_words=() heredoc_strip=() strip word c2 eol line
	while ((i < n)); do
		c="${s:i:1}"
		case "$c" in
		' ' | $'\t')
			if [ "$have" = 1 ]; then printf '%s\0' "$cur"; cur=""; have=0; fi
			i=$((i + 1))
			;;
		$'\n')
			if [ "$have" = 1 ]; then printf '%s\0' "$cur"; cur=""; have=0; fi
			printf '%s\0' $'\n'
			i=$((i + 1))
			# Drain every heredoc queued on the line that just ended, in order --
			# each one's body starts right where the previous one's terminator line
			# ended.
			while [ "${#heredoc_words[@]}" -gt 0 ]; do
				word="${heredoc_words[0]}"
				strip="${heredoc_strip[0]}"
				heredoc_words=("${heredoc_words[@]:1}")
				heredoc_strip=("${heredoc_strip[@]:1}")
				while :; do
					eol=$i
					while ((eol < n)) && [ "${s:eol:1}" != $'\n' ]; do eol=$((eol + 1)); done
					line="${s:i:$((eol - i))}"
					if [ "$strip" = 1 ]; then
						while [ "${line:0:1}" = $'\t' ]; do line="${line:1}"; done
					fi
					if [ "$line" = "$word" ]; then
						i=$eol
						((i < n)) && i=$((i + 1))
						break
					fi
					if ((eol >= n)); then
						i=$eol
						break
					fi
					i=$((eol + 1))
				done
			done
			;;
		'<')
			if [ "${s:i+1:1}" = '<' ] && [ "${s:i+2:1}" != '<' ]; then
				# A heredoc operator, not a `<<<` here-string (no body to skip).
				if [ "$have" = 1 ]; then printf '%s\0' "$cur"; cur=""; have=0; fi
				i=$((i + 2))
				strip=0
				if [ "${s:i:1}" = '-' ]; then
					strip=1
					i=$((i + 1))
				fi
				while ((i < n)) && { [ "${s:i:1}" = ' ' ] || [ "${s:i:1}" = $'\t' ]; }; do
					i=$((i + 1))
				done
				word=""
				if [ "${s:i:1}" = "'" ]; then
					i=$((i + 1))
					while ((i < n)) && [ "${s:i:1}" != "'" ]; do
						word+="${s:i:1}"
						i=$((i + 1))
					done
					((i < n)) && i=$((i + 1))
				elif [ "${s:i:1}" = '"' ]; then
					i=$((i + 1))
					while ((i < n)) && [ "${s:i:1}" != '"' ]; do
						if [ "${s:i:1}" = '\' ] && ((i + 1 < n)); then
							word+="${s:i+1:1}"
							i=$((i + 2))
						else
							word+="${s:i:1}"
							i=$((i + 1))
						fi
					done
					((i < n)) && i=$((i + 1))
				else
					while ((i < n)); do
						c2="${s:i:1}"
						case "$c2" in
						' ' | $'\t' | $'\n' | ';' | '&' | '|' | '(' | ')' | '`') break ;;
						'\')
							if ((i + 1 < n)); then
								word+="${s:i+1:1}"
								i=$((i + 2))
							else
								i=$((i + 1))
							fi
							;;
						*)
							word+="$c2"
							i=$((i + 1))
							;;
						esac
					done
				fi
				if [ -n "$word" ]; then
					heredoc_words+=("$word")
					heredoc_strip+=("$strip")
				fi
			else
				have=1
				cur+="$c"
				i=$((i + 1))
			fi
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
	';' | '&' | '|' | '(' | '`' | $'\n' | do | then | else | '{' | '!') return 0 ;;
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
		# Any global option before the subcommand, skipped fail-safe rather than off a closed
		# whitelist: a `-`-prefixed token we do not otherwise recognise (`-c pager.grep=false`,
		# `--git-dir=...`, `-P`, `--literal-pathspecs`, ...) is still skipped, or an unfamiliar
		# one would silently stop the scan before it ever reaches `grep`. Only the handful git
		# itself defines as taking a separate argument (rather than one glued on with `=`) also
		# skip that argument token.
		while [ "$j" -lt "$n" ]; do
			case "${toks[$j]}" in
			-C | -c | --git-dir | --work-tree | --namespace | --exec-path)
				j=$((j + 2)) # the option and its separate argument
				;;
			-*)
				j=$((j + 1)) # any other global option, no separate argument assumed
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
				';' | '&' | '|' | ')' | '`' | $'\n') break ;;
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
