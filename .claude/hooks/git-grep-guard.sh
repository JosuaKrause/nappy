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
# A shell parser keeps having holes, and a hole here crashes the machine -- an earlier version of
# this file tracked quotes, command boundaries and heredoc bodies to tell a real invocation from a
# mention, and review after review found a shape it let through: a wrapper (`timeout 5 git grep`,
# `sudo`, `env`, `find | xargs git grep`), a heredoc fed to an interpreter (`bash <<EOF ... git grep
# ... EOF`, `ssh host <<EOF`), quoted code run by a nested interpreter (`bash -c "git grep ..."`,
# `python3 -c "os.system('git grep ...')"`). So this file no longer tries to tell those apart: it
# matches on the raw command text, quotes and heredoc bodies included, and **prefers a false deny
# to a false allow**. Any `git`, followed later by `grep` as its own word -- with any git options
# between, and `grep` never counting when it is glued onto a `-`, so `git log --grep=foo` and
# `git shortlog --grep=foo` are the one shape this still allows -- is an invocation, denied unless
# that same invocation carries `-I` or a `--` pathspec made only of known-text-extension globs.
# **A mention now denies too** -- `echo "git grep"`, a commit message, a heredoc to `cat` -- since
# telling a mention from a real invocation is exactly the parsing this file no longer attempts. The
# deny reason names the workaround: write it as `git-grep` (a mention never tokenizes as the bare
# word `git` immediately followed by `grep`) or add `-I`.
#
# Raw-text matching still had four holes that need no obfuscation at all, found by a later review:
# `git \`<newline>`grep ...` (bash joins a backslash-newline pair back into one line, so treating it
# as a hard boundary was the bug); `/usr/bin/git grep ...` (an exact-string compare to `git` never
# matches a path); `GIT GREP ...` (this Mac's case-insensitive, case-preserving disk runs `GIT` as
# the same binary); and `g\it grep ...` (an unquoted mid-word backslash is a no-op escape bash
# itself strips). The command text is normalised before tokenising to close all four: a backslash-
# newline pair is deleted first, whole, joining the halves exactly as bash would, rather than
# leaving a bare newline the tokenizer would still treat as a separator; every remaining backslash
# is then deleted, so an escaped letter spells the word it escapes; and the two places this file
# asks "is this token the word `git` / `grep`?" compare the token's last path component case-
# insensitively rather than by exact string, so `/usr/bin/git`, `./git` and `GIT` all still count.
# `-I`, the `--` pathspec and every other flag stay compared case-sensitively, on the untouched
# token -- folding `-I` (skip binary files) together with `-i` (ignore case) would make a real,
# unbounded `git grep -i ... docs/` indistinguishable from a guarded one, which is the one false
# allow this file cannot reintroduce. `$(echo git) grep ...` and a shell alias stay the two named,
# accepted exceptions: the former never places `git` and `grep` as adjacent bare words (the
# substituted word lands as `echo`'s own argument), and the latter cannot be seen at the text layer
# at all.
#
# Reads the hook JSON on stdin. Denies via hookSpecificOutput.permissionDecision (PreToolUse "deny"
# JSON, see the pull request description for the doc citation confirming this shape and that
# PreToolUse fires for a sub-agent's own tool calls too -- a sub-agent is what ran the command
# above). Bash 3.2-safe, jq and bash only -- no external tokenizer, no rg, no python; case-
# insensitive matching uses bash's own `nocasematch` shell option, toggled on and back off around
# one comparison at a time so it never leaks into the case-sensitive checks below.

set -uo pipefail

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool" = "Bash" ] || exit 0
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$command" ] && exit 0

# ------------------------------------------------------------------------- normalise ------------
# Deletes every backslash-newline pair first (as a pair, so the join leaves nothing between the two
# former lines -- exactly what bash itself does with a real line continuation), then deletes every
# remaining backslash (so `g\it` spells `git`). Both patterns are built with a doubled backslash in
# single quotes on purpose: in a glob pattern (which is what the right-hand side of `${var//..}` is)
# a single `\` escapes the next character, so a *literal* one backslash has to be spelled as two.
bs_nl='\\'$'\n'
command="${command//$bs_nl/}"
bs='\\'
command="${command//$bs/}"

# ---------------------------------------------------------------------------- tokenizer --------
# Splits $1 into one token per output line, on whitespace alone: quotes, `$`, `<`, `(` and every
# other character are ordinary text, glued to whatever they are adjacent to, *except* `; & | ( ) `
# ' "`, each of which is its own one-character token -- which is only there to stop a quote mark
# from gluing onto an adjacent word (`"git` would otherwise never equal the word `git`), not to
# track whether anything is "inside" one: this scan does not know or care what is quoted, is inside
# a heredoc body, or is arguments to some other command, on purpose. A newline is also its own
# token, so a run of dash-flags and a pathspec are never credited to a `git grep` match that a
# different statement's `;`/`&`/`|`/newline actually separates it from.
#
# Tokens are printed NUL-separated (a token may legitimately contain other bytes) and read back
# with `read -d ''`, which is bash-3.2-safe.
tokenize() {
	local s="$1" i=0 n=${#1} c cur="" have=0
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
			;;
		';' | '&' | '|' | '(' | ')' | '`' | "'" | '"')
			if [ "$have" = 1 ]; then printf '%s\0' "$cur"; cur=""; have=0; fi
			printf '%s\0' "$c"
			i=$((i + 1))
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

# Case-insensitively compares $1 to $2, without leaking bash's `nocasematch` option to anything
# else in this file: turned on only for the one `[[ ... ]]` below, then off again before returning,
# so the case-sensitive checks this file relies on elsewhere (`-I` vs `-i`, a `*.md` extension)
# never see it.
eq_ci() {
	shopt -s nocasematch
	local result=1
	[[ "$1" == "$2" ]] && result=0
	shopt -u nocasematch
	return "$result"
}

# True for the bare word `git` / `grep`, case-insensitively, and also for either one written as a
# path (`/usr/bin/git`, `./git`) -- only the token's last path component is compared, so a
# directory earlier in the path can never itself read as `git` or `grep`.
is_git_token() { eq_ci "${1##*/}" "git"; }
is_grep_token() { eq_ci "${1##*/}" "grep"; }

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
	if is_git_token "${toks[$i]}"; then
		j=$((i + 1))
		# Any global option before the subcommand, skipped fail-safe rather than off a closed
		# whitelist: a `-`-prefixed token we do not otherwise recognise (`-c pager.grep=false`,
		# `--git-dir=...`, `-P`, `--literal-pathspecs`, ...) is still skipped, or an unfamiliar
		# one would silently stop the scan before it ever reaches `grep`. Only the handful git
		# itself defines as taking a separate argument (rather than one glued on with `=`) also
		# skip that argument token. This same loop is what makes `git log --grep=foo` safe: that
		# token is `-`-prefixed too, so it is skipped here rather than ever being compared to the
		# bare word `grep`.
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
		if [ "$j" -lt "$n" ] && is_grep_token "${toks[$j]}"; then
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
					# A bare quote mark around a pathspec (`'*.md'`) is its own token now
					# (see the tokenizer's header) and never itself a glob -- skip it
					# rather than let it fail the all-must-match check below.
					case "${toks[$t]}" in
					"'" | '"') ;;
					*)
						if ! is_text_glob "${toks[$t]}"; then
							text_only=0
							break
						fi
						;;
					esac
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

reason="This command's raw text has git followed by grep as its own word (a mention or a real \
invocation are treated the same on purpose -- see git-grep-guard.sh's own header), with neither -I \
nor a --pathspec restricted to text extensions in between. A real, unbounded git grep over this \
repo's ~900 MB docs/ (binaries included) has been measured to grow past 2.7 GB and keep climbing \
rather than finish. If this is only a mention, write it as git-grep instead of git grep. If it is a \
real search, add -I (skip binary files), restrict the pathspec to text globs (e.g. -- '*.md' \
'*.gd' '*.sh'), or use rg on the checkout instead of git grep. Flagged: ${findings[*]}"

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
exit 0
