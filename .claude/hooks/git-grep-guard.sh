#!/usr/bin/env bash
# Denies a `git grep` that can grow without bound.
#
# Without `-I`, git runs the pattern over every blob, binaries included. Over docs/ (about 900 MB of
# PNG/JPEG/MP4 evidence and JSON traces with 100 KB lines) a case-insensitive search was measured
# past 2.7 GB and still climbing at a 2-second cap, on the working tree alone and with `-F` alike,
# and one such search took down a 16 GB Mac. `-I` (skip binary files), or a `--` pathspec made only
# of known text-extension globs, keeps the same search between 15 MB and 916 MB and under two
# seconds. So a `git` followed by `grep` as a word of its own is denied unless that same invocation
# carries one of the two.
#
# **This prefers a false deny to a false allow.** A parser that tells a real invocation from a
# mention keeps having holes (a wrapper such as `timeout` or `xargs`, a heredoc fed to `bash` or
# `python3`, `bash -c "..."`, a Python string), and a hole here crashes the machine. So this reads
# the whole command text, heredoc bodies and quoted strings included, and a mention denies too
# (`echo "git grep"`, a commit message, `rg "git grep"`). The deny reason names the way out: write
# `git-grep` for a mention, and add `-I` to a search. What still passes is whatever never puts
# `grep` as its own word right after `git` and git's own options: `git log --grep=foo` (glued onto
# a dash), the bare word `git-grep`, `git log -S grep` (the subcommand is `log`), `git ... | grep`
# (a pipe ends the invocation), and prose such as "git, grep".
#
# How the text is read:
# - jq does all of the reading, in time linear in the text's length, because bash 3.2's string
#   operations and array lookups are not, and a hook that outruns its timeout lets the command
#   through. A backslash-newline pair is deleted first, joining the two lines as bash does, and the
#   `&` of a redirect (`2>&1`, `>&2`, `&>file`) is dropped, so it is not read as the `&` that ends a
#   command and the words after the redirect stay in the invocation. For the
#   first two readings, `${IFS}` and `$IFS` also become a space and `$'`/`$"` a plain quote, so
#   `git${IFS}grep` and `g$'i't` read as they run.
# - A text over 32 KB that holds both words is denied without being read further. Every reading
#   is linear, but the three together cost most on dense text of short words, where each word is
#   a step of its own: about 1.2 seconds at 32 KB of `git` on a line each, the slowest text
#   measured, against the hook's 10-second timeout, so a loaded machine still finishes in time.
#   Past the bound a real command holding both words is rare (a heredoc writing a large file), and
#   the way out is to write the text to a file first.
# - The text is then read three ways, and a match in any one of them denies:
#   1. every backslash and quote mark deleted, as bash's quote removal does, so `g"i"t`, `g\it`,
#      `"git" grep` and `git -C "$root" grep` read as they run;
#   2. every backslash deleted and every quote mark turned into a space, so a word glued onto a
#      quote still stands alone: `f"git grep ..."`, `cmd="git grep ..."; $cmd`, `bash <<<"git
#      grep ..."`, `os.system(r'git grep ...')`;
#   3. quotes and backslash escapes honoured, a quoted string staying inside its word, so a quoted
#      argument with a space stays one word (`git -C "/a b" grep`, `-c "x=bold red"`), a quoted
#      pattern such as `"gcc -I"` is not read as the `-I` flag, a quoted `'>'` or `'<'` is a
#      pathspec entry rather than a redirect, and a quoted `')'`, `'|'` or `\;` is an argument
#      rather than the end of the command.
#   In the first two readings a comma right after a quote mark splits words, which is how a Python
#   list (`["git", "grep", ...]`) reads; a comma anywhere else does not, so prose such as "git,
#   grep" is not an invocation. In the third reading every unquoted comma splits.
# - Words split on whitespace, `[` and `]`. `;`, `&`, `|`, `(`, `)`, a backtick and a newline are
#   words of their own, and each one ends an invocation's tail.
# - `git` is any word whose last path component is `git` in any case, a leading `$` ignored:
#   `/usr/bin/git`, `GIT` (this Mac's disk is case-insensitive, so it runs git), `$'git'`, `$git`.
#   `grep` is read the same way. A word with a `/` whose last component is `git-grep` is git's own
#   grep program (`"$(git --exec-path)/git-grep"`) and counts as both words at once.
# - Between `git` and `grep` may stand any `-` option (with the separate argument of the global
#   options that take one), a redirect, a newline (black puts `"git",` and `"grep",` on lines of
#   their own), and the `)` or backtick that closes `$(which git)`. A `grep` glued onto a dash is
#   never the word, so `git log --grep=foo` allows.
# - The tail runs from `grep` to the next separator word. Before `--`, its options are read as git
#   reads them: `-I` counts case-sensitively and is never folded together with `-i`, the last of
#   `-I` and `-a`/`--text`/`--no-text` wins (`-I -a` and `-Ia` search binaries as text), and the
#   argument of `-e`/`-f`/`-A`/`-B`/`-C`/`-m`, attached (`-eImport`) or the next word (`-e -I`), is
#   never a flag. The pathspec counts as text only if every entry after `--`, redirects aside, is
#   a text glob; an exclusion never counts, because an exclusion with nothing else searches
#   everything else. Any `!` or `^` in the short magic after the colon makes one
#   (`:!*.json`, `:^*.md`, `:/!*.json`, `:!/*.md`), and so does long magic naming `exclude`.
#
# Accepted holes, each needing a deliberate step: a shell alias or function, a git alias
# (`git -c alias.g=grep g ...`), a `git` or `grep` assembled by an expansion (`$(echo gi)t`,
# `$G` with G=git, any variable but IFS), an encoded command, a command kept in a file the command
# runs (`bash x.sh`, `python3 x.py`), an attributes file or `--attr-source` tree that marks the
# binaries as text (which voids `-I`), and a global option git adds later that takes a separate
# argument. Accepted false denies: a mention (`[git] grep` in prose and a path ending in
# `/git-grep` included), a line ending in `git` followed by a line starting with `grep`, a text-only pathspec
# that also carries an exclusion (`-- '*.md' ':!x.md'`), any long pathspec magic (`:(glob)*.md`,
# whose parentheses split it in the first two readings), and any command the jq program fails on.
#
# Guards both of Claude Code's tools that run a shell command: `Bash`, and `Monitor`, whose script
# runs in the same shell and lives for minutes. Reads the hook JSON on stdin (`tool_input.command`
# for both; a `command` given as an argument list is joined with spaces) and denies with
# PreToolUse's `permissionDecision: "deny"` JSON, which also stops a sub-agent's call.
# Needs bash 3.2 and jq only.

set -uo pipefail

# ------------------------------------------------------------------------------ the check (jq) ---
# Prints the unguarded invocations it finds, joined by "; ", and nothing when there is none. Every
# step is a literal split/join, one foreach over the characters, or a walk over an array of words,
# never a regex over the whole text and never an append to an array held in a reduce's state: jq's
# match, scan and gsub cost the length of the text per match, jq copies a state array on each
# append, and bash 3.2's arrays cost their length per lookup, any of which makes a long heredoc
# outrun the hook's timeout.
read -r -d '' check_program <<'JQ'
def drop($c): split($c) | join("");
def swap($c; $r): split($c) | join($r);

# Readings 1 and 2 split on whitespace, `[` and `]`; each separator is a word of its own.
def plain_words:
  [swap("\t"; " ") | swap("["; " ") | swap("]"; " ")
   | swap(";"; " ; ") | swap("&"; " & ") | swap("|"; " | ") | swap("("; " ( ") | swap(")"; " ) ")
   | swap("`"; " ` ") | swap("\n"; " \n ")
   | split(" ")[] | select(length > 0)];

# Reading 3 honours quotes and backslash escapes: a quoted string stays inside its word, and a
# newline inside one becomes a space. A word that had any quoting and looks like a redirect (`'>'`,
# `"2>"`, `\<`) or is a separator (`')'`, `'|'`, `\;`, git grep's own `\( ... \)` grouping) is a
# literal argument to bash, so it gets a leading \u0001 that no redirect, separator, option or text
# glob starts with. `foreach` hands each finished word straight to the collecting `[...]`
# rather than appending it to an array in the state, which jq would copy on every append and make
# the reading quadratic in the number of words; a `null` after the last character flushes the last
# word.
def flush:
  if .cur != "" then
    .emit += [if .quoted and ((.cur[0:3] | test("^[0-9]{0,2}[<>]")) or (.cur | IN(";", "&", "|", "(", ")", "`")))
              then "\u0001" + .cur else .cur end]
    | .cur = ""
  else . end
  | .quoted = false;
def quoted_words:
  [foreach ((explode[] | [.] | implode), null) as $c
     ({q: 0, esc: false, quoted: false, cur: "", emit: []};
      .emit = []
      | if $c == null then flush
        elif .esc then .cur += $c | .esc = false
        elif .q == 1 then (if $c == "'" then .q = 0 else .cur += $c end)
        elif .q == 2 then
          (if $c == "\\" then .esc = true elif $c == "\"" then .q = 0 else .cur += $c end)
        elif $c == "\\" then .esc = true | .quoted = true
        elif $c == "'" then .q = 1 | .quoted = true
        elif $c == "\"" then .q = 2 | .quoted = true
        elif $c == " " or $c == "\t" or $c == "," or $c == "[" or $c == "]" then flush
        elif $c == ";" or $c == "&" or $c == "|" or $c == "(" or $c == ")" or $c == "`" or $c == "\n"
        then flush | .emit += [$c]
        else .cur += $c end;
      .emit[])
   | if . == "\n" then . else swap("\n"; " ") end];

# `git` / `grep` in any case, as a path or not, a leading `$` ignored.
def last_part: (split("/") | last // "") | ltrimstr("$") | ascii_downcase;
def is_git: last_part == "git";
def is_grep: last_part == "grep";
# One short-option cluster (`-nIi`), read letter by letter as git's option parser does: `I` skips
# binaries, `a` searches them as text, and the later one wins; `e`, `f`, `A`, `B`, `C` and `m` take an
# argument, which is the rest of the cluster (`-eImport`) or, when nothing follows, the next word;
# `O` takes only an attached one. Gives {I: true/false/null (no change), next: 1 or 2 words}.
def short_cluster:
  reduce (.[1:] | explode[] | [.] | implode) as $c ({I: null, stop: false, arg: false};
    if .stop then .arg = false
    elif $c == "I" then .I = true
    elif $c == "a" then .I = false
    elif $c | IN("e", "f", "A", "B", "C", "m") then .stop = true | .arg = true
    elif $c == "O" then .stop = true
    else . end)
  | {I, next: (if .arg then 2 else 1 end)};
# True when the options before `--` end with binaries skipped: the last of `-I` and `-a`/`--text`
# (or `--no-text`, which restores the default of searching them) wins, case-sensitively, and `-I`
# is never folded together with `-i`.
def skips_binaries($opts):
  {t: 0, I: false}
  | until(.t >= ($opts | length);
      $opts[.t] as $x
      | if $x == "--text" or $x == "--no-text" then .I = false | .t += 1
        elif ($x | startswith("-")) and ($x | startswith("--") | not) and ($x | length) > 1 then
          ($x | short_cluster) as $r
          | (if $r.I == null then . else .I = $r.I end) | .t += $r.next
        else .t += 1 end)
  | .I;
# The words a redirect takes (2 when its target is the next word, 1 when glued on), else 0.
def redirect_width:
  sub("^[0-9]{0,2}"; "") as $w
  | if ($w | test("^[<>]")) | not then 0 elif ($w | test("^[<>]+$")) then 2 else 1 end;
# A pathspec exclusion: short magic after `:` whose leading run of `/`, `!`, `^` holds a `!` or `^`
# (`:!x`, `:^x`, `:/!x`, `:!/x`), or long magic `:(...)` naming `exclude` or holding `!`/`^`.
def is_exclusion:
  startswith(":")
  and (if startswith(":(") then ltrimstr(":(") | split(")")[0] | ascii_downcase | test("exclude|[!^]")
       else .[1:] | test("^[/!^]*[!^]") end);
# A pathspec entry restricted to a known text extension; an exclusion never counts.
def text_glob:
  if is_exclusion then false
  else test("\\.(md|gd|sh|py|json|toml|txt|cfg|ini|yml|yaml|csv|svg|html|htm|css|js|ts|xml|"
            + "rs|go|c|h|cpp|hpp|java|rb|pl|tres|tscn|gdshader|glsl|cs)$")
  end;
def is_sep: IN(";", "&", "|", ")", "`", "\n");
def takes_argument:
  IN("-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--config-env",
     "--attr-source");

# From the index after `git`, the index of the first word that is not one of git's own options (with
# a separate argument where it takes one), a redirect, a newline, or the `)`/backtick closing
# `$(which git)`. An unrecognised `-` option is skipped too, so an unfamiliar one cannot hide
# `grep`; the same skip keeps `git log --grep=foo` safe.
def after_options($w):
  until(. >= ($w | length)
        or ($w[.] as $x
            | ($x | startswith("-")) or ($x | IN("\n", ")", "`")) or ($x | redirect_width) > 0
            | not);
    $w[.] as $x
    | if $x | takes_argument then . + 2
      elif ($x | startswith("-")) or ($x | IN("\n", ")", "`")) then . + 1
      else . + ($x | redirect_width) end);

# True when a `--` pathspec is present and every entry, redirects aside, is a text glob.
def text_only($specs):
  {t: 0, entries: 0, ok: true}
  | until(.t >= ($specs | length) or (.ok | not);
      ($specs[.t] | redirect_width) as $r
      | if $r > 0 then .t += $r
        elif $specs[.t] | text_glob then .entries += 1 | .t += 1
        else .ok = false end)
  | .ok and .entries > 0;

# The tail after `grep` carries neither `-I` before `--` nor a text-only pathspec after it.
def unguarded($tail):
  (first(range(0; $tail | length) | select($tail[.] == "--")) // null) as $dd
  | skips_binaries(if $dd == null then $tail else $tail[:$dd] end) as $has_I
  | ($dd != null and text_only($tail[$dd + 1:])) as $text
  | ($has_I or $text) | not;

# Each unguarded `git ... grep <tail>` in the word array, the tail ending at the next separator.
# A path to git's own `git-grep` program (`$(git --exec-path)/git-grep`) is `git grep` in one word;
# the bare word `git-grep`, with no `/`, stays a mention.
def is_git_grep_path: contains("/") and last_part == "git-grep";
def findings:
  . as $w
  | ($w | length) as $n
  | {i: 0, out: []}
  | until(.i >= $n;
      (if $w[.i] | is_git_grep_path then .i
       elif $w[.i] | is_git then
         (.i + 1 | after_options($w)) | if . < $n and ($w[.] | is_grep) then . else null end
       else null end) as $j
      | if $j == null then .i += 1
        else ($j + 1 | until(. >= $n or ($w[.] | is_sep); . + 1)) as $k
          | (if unguarded($w[$j + 1:$k])
             then .out += [[["git"] + $w[$j:$k] | .[] | swap("\n"; " ")] | join(" ")]
             else . end)
          | .i = $k
        end)
  | .out;

if (.tool_name | IN("Bash", "Monitor")) | not then empty else
  (.tool_input.command // "")
  | (if type == "string" then . elif type == "array" then map(tostring) | join(" ") else "" end)
  | (drop("\\\n") | swap(">&"; ">") | swap("<&"; "<") | swap("&>"; ">")) as $raw
  # `${IFS}` and `$IFS` are word breaks, and `$'...'`/`$"..."` are quotes, for readings 1 and 2.
  | ($raw | swap("${IFS}"; " ") | swap("$IFS"; " ") | swap("$'"; "'") | swap("$\""; "\"")) as $bare
  | ($bare | drop("\\") | drop("\"") | drop("'") | ascii_downcase) as $flat
  # Every match needs both words, so most commands stop here.
  | if ($flat | contains("git") and contains("grep")) | not then empty
    elif ($raw | length) > 32768 then
      "(the whole command: over 32 KB and holding both words, too long to read in full inside the hook's timeout; write the long text to a file first, then run a short command)"
    else
      ($bare | drop("\\") | swap("\","; "\" ") | swap("',"; "' ")) as $unescaped
      | first(
          ($unescaped | drop("\"") | drop("'") | plain_words | findings),
          ($unescaped | swap("\""; " ") | swap("'"; " ") | plain_words | findings),
          ($raw | quoted_words | findings)
          | select(length > 0))
      | join("; ")
    end
end
JQ

# A failure of the program itself denies rather than letting the command through; only a missing
# jq, which every hook here needs, passes everything.
command -v jq >/dev/null 2>&1 || exit 0
if ! flagged=$(jq -r "$check_program" 2>/dev/null); then
	flagged="(the guard's own jq program failed on this command, so it could not be checked)"
fi
[ -z "$flagged" ] && exit 0

reason="This command's text has git followed by grep as a word of its own, with neither -I nor a \
-- pathspec restricted to text extensions, or it could not be read in full (see Flagged below). A \
mention and a real invocation are treated the same on purpose; see .claude/hooks/git-grep-guard.sh. \
A git grep without -I over this repo's ~900 MB docs/, binaries included, has been measured past \
2.7 GB and still growing. If this is only a mention, write \
git-grep instead of git grep. If it is a search, add -I (skip binary files), restrict the pathspec to \
text globs (e.g. -- '*.md' '*.gd' '*.sh'), or use rg on the checkout. Flagged: $flagged"

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
exit 0
