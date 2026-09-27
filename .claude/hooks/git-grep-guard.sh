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
# - A text over `too_long` (32 KB) skips every pass below and is decided by one regex test
#   instead: a backslash-newline pair, a lone backslash, a quote character or `$` may stand
#   between any two letters of `git` or of `grep`, so `g\it`, `g"i"t`, `g$'i't` and a word split by
#   a line continuation still read as the word; a command holding both words anywhere denies, one
#   holding neither allows. A newline on its own is not skipped, since the shell joins two lines
#   only at a backslash: prose with a line ending in `g` before one starting with `it` holds no
#   `git`. The length is checked before anything else because building the text the readings
#   below work on (dropping backslashes and quote marks, folding `${IFS}`) is itself a pass over
#   the whole command that costs seconds per megabyte on dense runs of the characters it drops,
#   and a hook that runs past its 10-second timeout lets the command through, in Claude Code and
#   in Codex alike. A real command over 32 KB holding both words is rare (a heredoc writing a
#   large file), and the way out is to write the text to a file first. Past `hard_cap` (1 MB) the
#   command is denied without the regex, as github-write-guard.sh denies every command past the
#   same size, so past it neither guard reads the command at all.
# - At or under 32 KB, the text is read in full, and no reading costs more than a few passes over
#   it: one pass over the characters, and over the words one table of where each word's run of
#   git options ends, built by pointer doubling (a pass over the words for each doubling of the
#   longest run) rather than walked from each `git` (`-c` swallows the next word, so in `git -c
#   git -c git ...` a walk from every `git` would run to the end of the chain, a cost quadratic in
#   its length). The densest texts of short words, where every word is a step of its own and all
#   four readings run to the end, are decided in about a second, well inside the hook's 10-second
#   timeout even on a loaded machine.
# - The text is then read four ways, and a match in any one of them denies:
#   1. every backslash and quote mark deleted, as bash's quote removal does, so `g"i"t`, `g\it`,
#      `"git" grep` and `git -C "$root" grep` read as they run;
#   2. every backslash deleted and every quote mark turned into a space, so a word glued onto a
#      quote still stands alone: `f"git grep ..."`, `cmd="git grep ..."; $cmd`, `bash <<<"git
#      grep ..."`, `os.system(r'git grep ...')`;
#   3. quotes and backslash escapes honoured, a quoted string staying inside its word, so a quoted
#      argument with a space stays one word (`git -C "/a b" grep`, `-c "x=bold red"`), a quoted
#      pattern such as `"gcc -I"` is not read as the `-I` flag, a quoted `'>'` or `'<'` is a
#      pathspec entry rather than a redirect, and a quoted `')'`, `'|'` or `\;` is an argument
#      rather than the end of the command;
#   4. a quoted script read as a script: quote marks and backslashes deleted as in reading 1, so the
#      words inside `bash -c '...'` stand out, but each word remembers which shell word it came
#      from, and which quoted word inside the script, so an option's argument is skipped whole at
#      the option's own level (`bash -c 'git -C "/x y" grep x'`, `bash -c "git -c 'a=b c' grep x"`,
#      `\"...\"` inside double quotes too) and a quoted pattern inside the script (`"gcc -I"`) is
#      not the `-I` flag. It runs only on a text holding a quote mark or a backslash, since without
#      one it is reading 1 again.
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
# binaries as text (which voids `-I`), a global option git adds later that takes a separate
# argument, and a third level of quoting (an escaped quote inside a quoted string inside a quoted
# script, `python3 -c 'os.system("git -C \"/x y\" grep x")'`), whose argument is not grouped.
# Accepted false denies: a mention (`[git] grep` in prose and a path ending in
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
# step is a literal split/join, one foreach over the characters, or a pass over an array of words,
# never an append to an array held in a reduce's state and never a walk that can start again from
# every word: jq's match, scan and gsub cost the length of the text per match, jq copies a state
# array that is read while it is updated, and bash 3.2's arrays cost their length per lookup, any
# of which makes a long heredoc outrun the hook's timeout. The one regex over the whole text is
# the over-bound test, a single search.
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

# Reading 4 reads a quoted script's own words: quote marks and backslashes are dropped as in
# reading 1, so the words inside `bash -c '...'` are split out, but whitespace inside quotes (or
# behind a backslash) becomes glue, U+0004, rather than a break, and U+0005 inside a second level of
# quotes within the first (a `"..."` inside `'...'`, a `'...'` or `\"...\"` inside `"..."`).
# `leveled_parts` then splits at the glue and gives each part a level (0 the first part of a shell
# word, 1 a later part of it, 2 a later part inside the second level of quotes), so
# `bash -c 'git -C "/x y" grep x'` skips `"/x y"` whole as `-C`'s argument and reaches `grep`.
def glued_text:
  [foreach explode[] as $c ({q: 0, iq: false, esc: false, emit: []};
     (if .iq then 5 else 4 end) as $g
     | if .esc then
         .esc = false
         | .emit = (if $c == 32 or $c == 9 then [$g] else [$c] end)
         | (if .q == 2 and $c == 34 then .iq = (.iq | not) else . end)
       elif $c == 92 and .q != 1 then .esc = true | .emit = []
       elif .q == 0 then
         (if $c == 39 then .q = 1 | .emit = [] elif $c == 34 then .q = 2 | .emit = []
          else .emit = [$c] end)
       elif (.q == 1 and $c == 39) or (.q == 2 and $c == 34) then .q = 0 | .iq = false | .emit = []
       elif (.q == 1 and $c == 34) or (.q == 2 and $c == 39) then .iq = (.iq | not) | .emit = []
       elif $c == 32 or $c == 9 then .emit = [$g]
       else .emit = [$c] end;
     .emit[])]
  | implode;
def leveled_parts:
  [.[]
   | if (contains("\u0004") or contains("\u0005")) | not then {w: ., c: 0}
     else
       [split("\u0004") | to_entries[] | .key as $j
        | .value | split("\u0005") | to_entries[]
        | {w: .value, c: (if .key > 0 then 2 elif $j > 0 then 1 else 0 end)}]
       | map(select(.w | length > 0))
       | (if length > 0 then .[0].c = 0 else . end)
       | .[]
     end];

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

# Follows every pointer in an array of forward pointers to its end: each entry is the index it
# points at, one that points at itself is an end, and the last entry is the array's own end. Each
# pass replaces a pointer with its pointer's pointer, which halves every remaining chain, so it
# takes a number of passes logarithmic in the longest chain and each pass is one read of the
# array; a walk from each start instead costs the length of the text for each start.
def resolve: until(. as $p | all(range(length); $p[$p[.]] == $p[.]); . as $p | map($p[.]));

# For every index in the word array (and one past its end), the index of the first word from there
# on that is not one of git's own options (with a separate argument where it takes one), a
# redirect, a newline, or the `)`/backtick closing `$(which git)`. An unrecognised `-` option is
# skipped too, so an unfamiliar one cannot hide `grep`; the same skip keeps `git log --grep=foo`
# safe. It is a table built once rather than a walk from each `git`, because `-c` swallows the next
# word: in `git -c git -c git ...` the walk from every `git` runs to the end of the chain, and a
# walk per `git` costs the square of the chain's length.
#
# With levels (`$lv`, reading 4 only), an option and its argument are each skipped as a whole word
# at the option's own level, so `-C "/x y"` inside a quoted script is two words, not three.
def word_ends($lv):
  ($lv | length) as $n
  | [foreach range($n - 1; -1; -1) as $p ({z: $n, o: $n, out: null};
       .out = {z, o}
       | (if $lv[$p] == 0 then .z = $p else . end)
       | (if $lv[$p] <= 1 then .o = $p else . end);
       .out)]
  | reverse;
def options_table($lv):
  . as $w
  | length as $n
  | (if $lv == null then null else word_ends($lv) end) as $ends
  | def word_end($l; $p):
      if $ends == null or $p >= $n then $p + 1
      elif $l == 0 then $ends[$p].z elif $l == 1 then $ends[$p].o else $p + 1 end;
    [range($n) as $i
     | $w[$i] as $x
     | ($lv[$i] // 0) as $l
     | (if ($x | startswith("-")) then (if $x | takes_argument then 2 else 1 end)
        elif $x | IN("\n", ")", "`") then 0
        elif ($x | contains("<") or contains(">")) then ($x | redirect_width)
        else -1 end) as $width
     | if $width < 0 then $i
       elif $width == 0 then $i + 1
       else word_end($l; $i) as $e
         | (if $width == 2 and $e < $n then word_end($l; $e) else $e end)
       end
     | if . > $n then $n else . end]
    + [$n]
  | resolve;

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
def findings($lv):
  . as $w
  | ($w | length) as $n
  | ($w | options_table($lv)) as $after_options
  | {i: 0, out: []}
  | until(.i >= $n;
      (if $w[.i] | is_git_grep_path then .i
       elif $w[.i] | is_git then
         $after_options[.i + 1] | if . < $n and ($w[.] | is_grep) then . else null end
       else null end) as $j
      | if $j == null then .i += 1
        else ($j + 1 | until(. >= $n or ($w[.] | is_sep); . + 1)) as $k
          # In reading 4 a later part of a quoted argument (`"gcc -I"`) is never an option.
          | (if unguarded(if $lv == null then $w[$j + 1:$k]
                          else [range($j + 1; $k) | select($lv[.] <= $lv[$j]) | $w[.]] end)
             then .out += [[["git"] + $w[$j:$k] | .[] | swap("\n"; " ")] | join(" ")]
             else . end)
          | .i = $k
        end)
  | .out;

# Past `too_long`, none of the passes below run at all: one regex test decides instead, as the
# header says, since `$raw`, `$bare` and `$flat` are each a pass over a command of unbounded
# length. A command holding neither word, however the shell would have joined, quoted or expanded
# its letters, cannot be a `git ... grep` invocation at all, so it allows. Between two letters the
# regex skips a backslash-newline pair, a lone backslash, a quote mark and a `$`, never a newline
# on its own: the shell joins two lines only at a backslash, so a line ending in `g` before a line
# starting with `it` is two words. Past `hard_cap` nothing is read at all and the command is
# denied, as github-write-guard.sh denies it.
def too_long: 32768;
def hard_cap: 1048576;
def skip: "(?:\\\\\n|[\\\\\"'$])*";
def obscured($word): ($word | split("") | join(skip));
def over_bound_verdict:
  if (test(obscured("git"); "i") and test(obscured("grep"); "i"))
  then "(the whole command: over 32 KB and holding both words, not read further; write the long text to a file first, then run a short command)"
  else empty
  end;

if (.tool_name | IN("Bash", "Monitor")) | not then empty else
  (.tool_input.command // "")
  | (if type == "string" then . elif type == "array" then map(tostring) | join(" ") else "" end)
  | if length > hard_cap
    then "(the whole command: over 1 MB, not read at all; write the long text to a file first, then run a short command)"
    elif length > too_long then over_bound_verdict
    else
      (drop("\\\n") | swap(">&"; ">") | swap("<&"; "<") | swap("&>"; ">")) as $raw
      # `${IFS}` and `$IFS` are word breaks, and `$'...'`/`$"..."` are quotes, for readings 1 and 2.
      | ($raw | swap("${IFS}"; " ") | swap("$IFS"; " ") | swap("$'"; "'") | swap("$\""; "\"")) as $bare
      | ($bare | drop("\\") | drop("\"") | drop("'") | ascii_downcase) as $flat
      # Every match needs both words, so most commands stop here.
      | if ($flat | contains("git") and contains("grep")) | not then empty
        else
          ($bare | drop("\\") | swap("\","; "\" ") | swap("',"; "' ")) as $unescaped
          | first(
              ($unescaped | drop("\"") | drop("'") | plain_words | findings(null)),
              ($unescaped | swap("\""; " ") | swap("'"; " ") | plain_words | findings(null)),
              ($raw | quoted_words | findings(null)),
              # Reading 4 differs from reading 1 only where there is a quote or a backslash.
              ($bare | select(test("['\"\\\\]")) | glued_text | plain_words | leveled_parts
               | (map(.c)) as $lv | map(.w) | findings($lv))
              | select(length > 0))
          | join("; ")
        end
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
