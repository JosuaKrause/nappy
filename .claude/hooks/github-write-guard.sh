#!/usr/bin/env bash
# Denies a command that writes to GitHub unless it runs through an agent's own identity.
#
# CLAUDE.md's committing/pr-review skills make this mandatory: a write on a pull request that
# changes code goes out as a coder identity (`claude-coder`/`codex-coder`), Claude Code's issue
# writes and writes on a pull request with no code changes as `claude-orchestrator` (Codex's stay
# `codex-coder`'s), a review as a reviewer identity (`claude-reviewer`/`codex-reviewer`), and
# when `tools/agent-identity.py status <role>` says a role is not usable, the session stops and
# tells the player rather than
# falling back to a direct call under the player's own account. A rule that is only ever obeyed by
# remembering it is not a rule -- this is the mechanical half, denying the direct call so the
# wrapped one is the only one that works.
#
# **The bar this holds itself to: a guardrail, not a security boundary.** It stops an agent's
# ordinary GitHub writes from going out as the player by mistake -- every shape an agent would
# plausibly type is fixed. It does not chase a deliberately adversarial shape meant to evade it:
# the wrapper's shape inside a mention (below), a write through a client other than git, gh or the
# pushing scripts (`curl` with `gh auth token`, an MCP tool), a command naming a role that is not
# the running agent's own, a GraphQL merge mutation under a reviewer role, and a wrapper inside a
# quoted script whose `--` is spelled with escapes (`\"--\"`, `\-\-`) are accepted gaps, each with
# an example in
# `docs/decisions/2026-09-27-tall-egret.md`'s "Accepted gaps" paragraph. So is an option argument
# with a space in it under a third level of quoting (an escaped quote inside a quoted string
# inside a quoted script, `python3 -c 'os.system("git -C \"/x y\" push")'`), which is not grouped.
# So is a `gh api` call's own quoted argument holding a separator and then a git or gh command
# word (`--jq '.x; git' -X POST`): the separator reads as the end of the call's flags, so a write
# flag after that argument is not seen.
#
# A "write" is `git push`; a commit-making git verb (`commit` always; `cherry-pick`/`revert`/`am`
# unless they carry `--abort`/`--quit`; `merge`/`rebase` unless `--abort`/`--no-commit`/
# `--ff-only`; `pull` unless `--ff-only`, the only shape that cannot make a commit of its own);
# any `gh` noun's verb that is not on one short, shared read list (`view`, `list`, `status`,
# `diff`, `checks`, `checkout`, `watch`, `download`, `clone`, `token`) -- every noun, not only
# `pr`/`issue`/`release`, so `gh workflow run`, `gh run rerun`, `gh repo edit`, `gh label create`,
# `gh secret set`, `gh variable set`, `gh cache delete` and `gh gist create` all write and are
# caught the same fail-safe way an unknown verb is (`gh browse` and `gh search` are read nouns
# whole, with no verb of their own to check); `gh api` with a non-GET method or
# `-f`/`-F`/`--input`/`--raw-field`/`--field`, attached or not, wherever the flag falls relative to
# the endpoint, unless the method is an explicit GET (gh then sends the fields as query
# parameters) -- a GraphQL call (`gh api graphql`) reads only when its query is written inline on
# the command line and contains no `mutation`, and writes when it does or when its query comes from
# a file, a shell expansion or `--input`, where the word cannot be checked; or one of the `tools/*.sh`
# scripts whose own body pushes or posts (`tools/release.sh`, `tools/prune-merged.sh`,
# `tools/land-prs.sh`, `tools/update-pr.sh` -- found with `rg` for `git push|git commit|gh pr |gh
# issue |gh release|gh api` over `tools/*.sh`; a script that only reads, such as
# `tools/agent-status.sh`'s `gh pr view`, is not on this list), and only when its name is in
# command position (the first word of a command, past any `NAME=value` assignment or a wrapper
# word's own options -- `bash`/`sh`/`env`/`timeout`/`xargs`/`nice`/`nohup`/`sudo`/`command`/`watch`/
# `stdbuf`/`caffeinate`/`time`/`exec`/`eval`, as a bare word or a path (`/usr/bin/env`), and the
# shell's reserved words `do`/`then`/`else`/`elif`/`if`/`while`/`until`/
# `{`/`!`, `timeout` alone also taking one bare duration, and the argument of a wrapper option
# that takes one (`sudo -u root`, `sudo -iu root`, `nice -n 10`, `timeout -s KILL`, `xargs -n 1`,
# `exec -a name`) skipped with it; the script after `bash -c`/`sh -c` is a command of its own, so
# its first word is in command position too --
# never where its name is merely a read's argument
# (`cat`, `sed`, `git log --`/`diff --`/`show`, `rg`)), and, for `release.sh`, only with its own
# `push` argument, for `land-prs.sh`/`update-pr.sh`, only without their own `--dry-run`.
# Reads (`git status`, `git fetch`, `git log`, `gh pr view/list/diff/checks/checkout`, `gh
# issue/release list/view`, `gh run watch/download`, `gh repo clone`, `gh auth token`, `gh
# search`, `gh browse`, a GET `gh api` with or without fields, an inline GraphQL query with no
# `mutation`) stay unguarded.
#
# **A reviewer identity (`claude-reviewer`, `codex-reviewer`) is refused the named push and merge
# routes, wrapped or not.** Its GitHub App has `contents: write` (a reviewer's own APPROVE needs it to satisfy a
# required-approval ruleset, and so does resolving its own review threads -- see
# `_REVIEWER_PERMISSIONS`'s own comment in `tools/agent-identity.py`), so GitHub itself would let
# it push or merge; this tool still refuses, on the theory that reviewing and coding stay two
# identities even where GitHub's permission model would allow one to do both. So `git push`, the
# pushing `tools/*.sh` scripts, `gh pr merge`, `gh pr update-branch` and a `gh api` write whose
# endpoint ends in `/merge`, `/merges` or `/update-branch` (with an optional trailing `/` or
# `?query`) or goes to a `/contents/` or `/git/refs` path are all denied even inside `run
# claude-reviewer --`/`run codex-reviewer --`, with a message naming the identities to use
# instead. A GraphQL mutation is not refused by name: `resolveReviewThread`, which a reviewer
# needs, is one, so `mergePullRequest` or `enablePullRequestAutoMerge` under a reviewer role is an
# accepted gap. Every other role is a wrapping role that pushes and merges: the coders
# (`claude-coder`, `codex-coder`) on a pull request that changes code, and `claude-orchestrator` on
# one with no code changes and on issues. Which of those a write goes out as is committing's
# convention, never checked here. A role this hook
# does not recognise as a reviewer is not specially blocked here either way:
# `tools/agent-identity.py` itself refuses to mint a token for a name outside its own `ROLE_NAMES`,
# which is the actual enforcement for an unknown or misspelled role.
#
# The escape is `tools/agent-identity.py run <role> -- <command>`, with or without a `uv run
# python` (or bare `python`/`python3`) in front, and with or without `run`'s own `--repo
# OWNER/REPO` between `run` and `<role>`: everything at and after that literal `--`, up to the
# next real command separator, is exempt. Nothing before the `--`, or in a different
# `;`/`&`/`|`/newline-separated command on the same line, is. A wrapper written inside a quoted
# script (`bash -c "... run claude-coder -- git fetch; git push"`) reaches only as far as the
# shell running that script lets it, the script's own next `;`, `&&`, `|` or newline, so the
# `git push` there is denied.
#
# **This prefers a false deny to a false allow**, the same call `git-grep-guard.sh` makes and for
# the same reason: telling a mention from a real invocation is a parser that keeps having holes,
# and the failure mode of an over-eager deny (rerun the command through the wrapper) is far
# cheaper than the failure mode of a miss (a post lands under the player's own account again,
# which is the whole thing this rule exists to stop). So this reads the command's raw text, quotes
# and backslashes stripped before it is split into words, and a mention (a write's name inside an
# echo, a commit message, a code comment) denies exactly like a real invocation would. Each word
# still remembers which shell word it came from, and which quoted word inside a quoted script, so
# an option's argument is skipped whole however it is quoted, escaped or joined by a comma: `git
# -C "/x y" push`, `git -c 'a=b c' push`, `FOO="a b" tools/release.sh patch push` and `bash -c 'git
# -C "/x y" push'` all reach the push. When the reading is unsure (below), the same command is
# also read word by word, the way it would be with no quotes at all, and a write either way
# denies. Quotes are still read for one more thing first: a separator inside them (`--jq '.a | .b'`, `-f body='a; b'`, a
# `(` in an inline GraphQL query) is soft -- it still splits words, so a command inside `bash -c
# "..."` is still found, but it neither ends a `gh api` call's flags, so a write flag after the
# quoted argument is seen, nor ends the exemption of a wrapper standing outside the quotes, so
# `run <role> -- bash -c "a; b"` covers the whole script it runs. A wrapper inside the quotes is
# told apart by its quoted `--`, and its exemption ends at the next separator, soft or hard; a
# wrapper inside a script that an outer wrapper already covers (`run <role> -- bash -c "run
# <role> -- a; b"`) is then a false deny for `b`, the safe direction. A `--` spelled with escapes
# inside the quotes (`\"--\"`, `\-\-`) is not marked, so that wrapper reads as an outer one -- an
# accepted gap (see the list above).
#
# **The quote reading only ever narrows what a separator ends, and only where it can vouch for
# itself.** A separator read as soft is one a wrapper's exemption runs past, so a misread quote is
# a false allow: the next line's unwrapped write rides the wrapper. The character pass models
# exactly four of the shell's quoting states -- single quotes, double quotes, `$'...'` after an
# unescaped `$`, and a `#` comment -- plus the backslash, and switches between them on exactly the
# characters the shell switches on, so a command built from those alone has no misread path. Every
# other construct that changes how quotes are read is not modelled, and its mere presence anywhere
# in the command, quoted or not, makes the reading unsure: `$(` (so also `$((`), whose body inside
# `"..."` starts a fresh quoting context; a backtick, with its own backslash rules; `${`, whose word
# inside `"..."` can hold quotes of its own; `<<`, a heredoc body where quotes mean nothing (or a
# here-string); and `$$'`, where the pass cannot tell `$$` then `'...'` from `$` then `$'...'`. So
# is a command the pass finishes with a quote or an escape still open, since a command the shell
# accepts ends with its quotes closed. The simpler rule -- any of those anywhere -- is chosen over
# "`$(` or a backtick inside double quotes" because it needs no argument about what the shell does
# inside each of them: a heredoc commit message, `"$(...)"` and `${VAR}` are all simply not read
# for quotes. An unsure command is read as if every separator were hard for the exemption (a
# wrapper covers only up to the next `;`, `&`, `|`, `(`, `)`, backtick or newline, quoted or not),
# and as if every separator were soft for a `gh api` call's flags (its scan runs on past a pipe or
# a `;` up to the next git, gh, wrapper or pushing-script command, so a write flag after a quoted
# `|` is still seen). Both are the stricter reading, and both cost false denies in exactly those
# commands: `run <role> -- bash -c "a; b"` beside a `$(...)` is denied, and so is a `gh api` read
# with no explicit GET piped into a command that takes `-f`, `-F`, `-X` or `--input` (`| grep -F
# x`). So is a line of heredoc prose that starts with a reserved word, `time`, `exec` or `eval` and
# then a pushing script's path (`if tools/land-prs.sh is named, it is read.`): every newline of an
# unsure command is a separator, and the word after a reserved word is read in command position.
# So is a wrapped heredoc commit or PR body whose text names a write (a line such as "run `git
# push` through the wrapper"): the heredoc makes the command unsure, its first newline ends the wrapper's reach, and
# the mention after it reads as an unwrapped write. When the denied command holds a wrapper, the
# deny message says so and points at a body file (`git commit -F file`, `--body-file file`, `gh api
# -F body=@file`), which the hook never reads. A command over 64 KB that names git, gh or a
# pushing script anywhere, even inside another word, is denied without being read, and one over
# 1 MB is denied outright (`too_long` and `hard_cap`, below), since a hook that runs past its
# timeout lets the command through in both Claude Code and Codex. The one
# case this does not close is the wrapper's own shape appearing whole inside a mention (a comment
# that quotes a full `tools/agent-identity.py run claude-coder -- git push` line reads, to this
# script, like a real wrapped call) -- an accepted hole, the same kind `git-grep-guard.sh` accepts
# for an encoded command or one kept in a file the shell then runs.
#
# Guards both of Claude Code's tools that run a shell command (`Bash`, `Monitor`) the same way
# `git-grep-guard.sh` does, and reads the same hook JSON shape on stdin. Needs bash 3.2 and jq only.

set -uo pipefail

read -r -d '' check_program <<'JQ'
def drop($c): split($c) | join("");
def swap($c; $r): split($c) | join($r);

# `git`/`gh`/`agent-identity.py`/a tools/ script name, in any case, as a bare word or a path, a
# leading `$` ignored -- the same "last path component" test git-grep-guard.sh uses for `git`/`grep`.
def last_part: (split("/") | last // "") | ltrimstr("$") | ascii_downcase;
def named($name): last_part == $name;

# A separator character (`;`, `&`, `|`, `(`, `)`, a backtick, a newline) that sits inside single
# quotes, double quotes or a `$'...'` string, or right behind a backslash, is "soft": it becomes
# the one-character word U+0001 instead of itself. A `--` that is a whole word inside quotes
# becomes `--` plus U+0002, so a wrapper written inside a quoted script (`bash -c "... run
# claude-coder -- git fetch; git push"`) is told apart from one standing outside it (`run
# claude-coder -- bash -c "..."`): the shell ends the inner wrapper's reach at the script's own
# `;`, `&&` or newline, and `findings` ends its exemption there too. One pass over the characters,
# tracking which quote is open (0 none, 1 single, 2 double, 3 `$'...'`, opened only by a `$` that
# is not itself escaped, where a backslash escapes as it does outside quotes and in double quotes,
# but not in single quotes, and `\n` is a newline, so a soft separator; 4 a `#` comment) and the
# two characters before the last, so a `--` is marked when the character that ends it arrives: the
# two before are `-`, the one before those starts a word, and a quote is still open. One sentinel
# character after the last closes the pass: it leaves U+0003 behind when a quote or an escape is
# still open, which makes the whole reading unsure (see the header).
#
# A backslash-newline joins two lines only where the shell joins them: outside quotes, in double
# quotes and in `$'...'` (where it stays a soft separator, the safer reading), never after an
# escaped backslash (`echo C:\\` then a newline is two commands) and never in a comment or in
# single quotes (a comment ending in `\` still ends at its newline). A joined newline emits
# nothing, and the characters before the backslash stay the ones a `#` or a `$'` looks back at,
# so `a\` newline `#x` is the word `a#x`, not a comment.
#
# An unquoted, unescaped `#` that starts a word (nothing, whitespace or `;`/`&`/`|`/`(`/`)`/a
# newline before it) opens a comment that the next newline closes, as the shell reads it: quotes
# and backslashes inside it change nothing, so an apostrophe in `# the player's words` never opens
# a quote that would soften every later separator and stretch a wrapper's exemption to the end of
# the command. Its words are still split and read, so a write named in a comment denies as a
# mention, and a separator in it stays hard (`# fine; git push` after a wrapped command denies).
#
# Every break the split below makes inside one shell word is marked as glue rather than a space:
# whitespace, a comma or a bracket inside quotes or behind a backslash, the spaces around a soft
# separator, and an unquoted comma or bracket (which the shell never splits on, though the split
# does, for a Python list's sake). The words come out the same, but `leveled_parts` can then tell
# which of them belong to one shell word, so a quoted option argument with a space in it (`git -C
# "/x y" push`, `git -c 'a=b c' push`, `FOO="a b" tools/release.sh ... push`) is skipped whole. The
# glue is U+0004, or U+0005 inside a second level of quotes within the first (a `"..."` inside
# `'...'`, a `'...'` or `\"...\"` inside `"..."`), so a script in quotes (`bash -c 'git -C "/x y"
# push'`) groups its own quoted arguments the same way. Every opening quote also leaves U+0006,
# dropped from any part that has other characters, so an empty quoted word (`git -C "" push`) is
# still a word for the option to take, and a second-level quoted argument that starts with a space
# (`bash -c "git -c ' x=1' push"`) still starts a word of its own level.
def sep_codepoints: [59, 38, 124, 40, 41, 96, 10];
def word_edge_codepoints: [32, 9, 10, 34, 39];
def comment_start_codepoints: [32, 9, 10, 59, 38, 124, 40, 41];
def glue_codepoints: [32, 9, 44, 91, 93];
# Membership in each set above as an array indexed by code point, so a character's class is one
# lookup rather than a search of the set on every character.
def codepoint_table($set): [range(128) as $c | ($set | index($c)) != null];
def mark_soft_separators:
  codepoint_table(sep_codepoints) as $is_sep
  | codepoint_table(glue_codepoints) as $is_glue
  | codepoint_table([44, 91, 93]) as $is_list_mark
  | codepoint_table(word_edge_codepoints) as $is_edge
  | codepoint_table(word_edge_codepoints + sep_codepoints) as $is_edge_or_sep
  | codepoint_table(comment_start_codepoints) as $is_comment_start
  | [foreach (explode + [3])[] as $c
      ({q: 0, iq: false, esc: false, prev: null, prev_esc: false, p2: null, p3: null, joined: false,
        emit: []};
      .prev as $prev
      | .esc as $escaped
      | (if .iq then 5 else 4 end) as $g
      | (if .q == 4 then [$c]
         elif .esc and .q == 3 and $c == 110 then [$g, 1, $g]
         elif (.esc or .q != 0) and $is_sep[$c] then [$g, 1, $g]
         elif (.esc or .q != 0) and $is_glue[$c] then [$g]
         elif $is_list_mark[$c] then [4]
         else [$c] end) as $out
      | .p3 as $p3
      | ((.esc | not) and .q != 0 and .q != 4 and .prev == 45 and .p2 == 45
         and ($p3 == null or $is_edge[$p3]) and $is_edge_or_sep[$c]) as $quoted_dashes
      | if $c == 3 then .emit = (if .esc or (.q | IN(1, 2, 3)) then [3] else [] end)
        elif .q == 4 then (if $c == 10 then .q = 0 else . end) | .emit = $out
        elif .esc and $c == 10 and .q != 3 then .esc = false | .emit = [] | .joined = true
        elif .esc then
          .esc = false | .emit = $out
          | (if .q == 2 and $c == 34 then .iq = (.iq | not) | .emit += [6] else . end)
        elif $c == 92 and .q != 1 then .esc = true | .emit = [$c]
        elif .q == 0 and $c == 35
             and ($prev == null or $is_comment_start[$prev])
        then .q = 4 | .emit = [$c]
        elif .q == 0 and $c == 39 then
          .q = (if .prev == 36 and (.prev_esc | not) then 3 else 1 end) | .emit = [$c, 6]
        elif .q == 0 and $c == 34 then .q = 2 | .emit = [$c, 6]
        elif (.q == 1 or .q == 3) and $c == 39 then .q = 0 | .iq = false | .emit = [$c]
        elif .q == 2 and $c == 34 then .q = 0 | .iq = false | .emit = [$c]
        else
          .emit = $out
          | (if ((.q == 1 or .q == 3) and $c == 34) or (.q == 2 and $c == 39)
             then .iq = (.iq | not) | .emit += [6] else . end)
        end
      | (if $quoted_dashes then .emit = [2] + .emit else . end)
      | if .joined then .joined = false | .prev = .p2 | .p2 = .p3 | .p3 = null | .prev_esc = false
        else .p3 = .p2 | .p2 = .prev | .prev = $c | .prev_esc = $escaped end;
      .emit[])]
  | implode;

# Quotes and backslashes are dropped before the split (mentions read like invocations, on
# purpose -- see the header). `,`, `[` and `]` join whitespace as word breaks (a Python argument
# list, `subprocess.run(["git", "push"])`, must not hide the words inside its brackets); `;`, `&`,
# `|`, `(`, `)`, a backtick and a newline are words of their own, each ending a chain of commands.
# Inside quotes they are soft separators instead (`mark_soft_separators`): still a word break
# every detector stops at, so a command inside `bash -c "..."` or `$(...)` is still seen, but not
# the end of a `gh api` call's own flags (`detect_gh_api`), since a quoted `--jq '.a | .b'` or
# `-f body='a; b'` is one argument, nor of the exemption of a wrapper standing outside the quotes
# (`findings`), since `run <role> -- bash -c "a; b"` runs the whole script as that role. A wrapper
# found through a quoted `--` (U+0002, above) is inside the script, and its exemption ends at the
# next separator, soft or hard. The `$'` and `$"` openers lose their `$` only here, after the
# pass, which needs to see it. When the reading is unsure (the header), every separator becomes
# soft for the scans and `findings` ends every exemption at any of them.
def split_words:
  swap("$'"; "'") | swap("$\""; "\"")
  | drop("\\") | drop("\"") | drop("'")
  | swap("\t"; " ") | swap(","; " ") | swap("["; " ") | swap("]"; " ")
  | swap(";"; " ; ") | swap("&"; " & ") | swap("|"; " | ")
  | swap("("; " ( ") | swap(")"; " ) ") | swap("`"; " ` ") | swap("\n"; " \n ")
  | split(" ") | map(select(length > 0));

# Splits every word at its glue into parts, each with a level: 0 for the first part of a shell
# word, 1 for a later part of it, 2 for a later part inside a second level of quotes. The parts,
# in order, are exactly the words a split at every glue would give.
def placeholder_or_word:
  if contains("\u0006") then (drop("\u0006") | if . == "" then "\u0006" else . end) else . end;
def leveled_parts:
  [.[]
   | if (contains("\u0004") or contains("\u0005") or contains("\u0006")) | not then {w: ., c: 0}
     else
       [split("\u0004") | to_entries[] | .key as $j
        | [.value | split("\u0005")[] | placeholder_or_word | select(length > 0)]
        | to_entries[]
        | {w: .value, c: (if .key > 0 then 2 elif $j > 0 then 1 else 0 end)}]
       | (if length > 0 then .[0].c = 0 else . end)
       | .[]
     end];

def is_sep: IN(";", "&", "|", "(", ")", "`", "\n", "\u0001");
def is_hard_sep: IN(";", "&", "|", "(", ")", "`", "\n");

# Global options taking a separate argument -- git's, gh's and agent-identity.py run's own
# --repo alike, one small list, fail-safe: an option not on it is skipped as one word, so an
# unfamiliar flag can never hide the word after it (the same call git-grep-guard.sh's
# options_table makes for git).
def takes_argument:
  IN("-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--config-env",
     "--attr-source", "-R", "--repo", "--hostname");

# Follows every pointer in an array of forward pointers to its end: each entry is the index it
# points at, one that points at itself is an end, and the last entry is the array's own end. Each
# pass replaces a pointer with its pointer's pointer, which halves every remaining chain, so it
# takes a number of passes logarithmic in the longest chain and each pass is one read of the
# array. The walks below (a run of options, a run of assignments and wrapper words) are tables
# built this way once per command rather than walked again from every word that starts one: `-c`
# swallows the next word, so in `git -c git -c git ...` or `; env -c ; env -c ...` a walk from
# every start runs to the end of the chain, a cost quadratic in its length.
def resolve: until(. as $p | all(range(length); $p[$p[.]] == $p[.]); . as $p | map($p[.]));

# The options each wrapper word takes with a separate argument, so the word after `sudo -u`,
# `nice -n`, `timeout -s` or `xargs -n` is skipped as that argument rather than taken for the
# command; `bash -c`/`sh -c` is not among them, since the word after `-c` is the script, whose
# own first word is in command position (`bash -c 'tools/prune-merged.sh x'`), and neither is
# `env -S`, whose argument is the command line itself.
def wrapper_argument_options:
  {sudo: ["-u", "-g", "-h", "-p", "-C", "-D", "-R", "-r", "-t", "-T", "-U", "--user", "--group",
          "--host", "--prompt", "--close-from", "--chdir", "--chroot", "--role", "--type",
          "--other-user", "--command-timeout"],
   env: ["-u", "-C", "-P", "--unset", "--chdir"],
   nice: ["-n", "--adjustment"],
   timeout: ["-s", "-k", "--signal", "--kill-after"],
   xargs: ["-n", "-I", "-L", "-P", "-s", "-d", "-E", "-a", "--max-args", "--max-lines",
           "--max-procs", "--max-chars", "--delimiter", "--eof", "--arg-file"],
   watch: ["-n", "--interval"],
   bash: ["-o", "-O", "--rcfile", "--init-file"],
   sh: ["-o", "-O"],
   exec: ["-a"],
   stdbuf: ["-i", "-o", "-e"],
   caffeinate: ["-t", "-w"]};
# For every index, the first index after it whose part starts a word at its own level or an
# outer one: `.z` for a level-0 option (the next shell word), `.o` for a level-1 one (the next word
# of a script in quotes). One pass from the end.
def word_ends($lv):
  ($lv | length) as $n
  | [foreach range($n - 1; -1; -1) as $p ({z: $n, o: $n, out: null};
       .out = {z, o}
       | (if $lv[$p] == 0 then .z = $p else . end)
       | (if $lv[$p] <= 1 then .o = $p else . end);
       .out)]
  | reverse;

# For every index in the word array (and one past its end), the index of the first word from there
# on that is not a leading `-`-prefixed option (or that option's own separate argument). With
# levels (`$lv`), an option and its argument are each skipped as a whole word at the option's own
# level, so `-C "/x y"` is two words, not three; with `$lv` null every part is a word of its own,
# which is how an unsure command is also read (see `findings`).
#
# With `$owners` (see `wrapper_owners`), the options read are a wrapper's own rather than git's
# and gh's: which of them take a separate argument depends on the wrapper they follow. `$g` is
# `{lv, ends}` (the levels and their `word_ends`, built once per command) or null.
def options_table($g; $owners):
  . as $w
  | length as $n
  | ($g.lv) as $lv
  | ($g.ends) as $ends
  | def word_end($l; $p):
      if $ends == null or $p >= $n then $p + 1
      elif $l == 0 then $ends[$p].z elif $l == 1 then $ends[$p].o else $p + 1 end;
    [range($n) as $i
     | $w[$i] as $x
     | if ($x | startswith("-")) | not then $i
       else
         ($lv[$i] // 0) as $l
         | word_end($l; $i) as $e
         | (if $owners == null then ($x | takes_argument)
            else (wrapper_argument_options[$owners[$i] // ""] // []) as $opts
              | ($opts | index($x)) != null
                # A cluster of short options (`sudo -iu root`) takes an argument when its last
                # letter does.
                or (($x | test("^-[A-Za-z]{2,}$")) and ($opts | index("-" + $x[-1:])) != null)
            end) as $arg
         | (if $arg and $e < $n then word_end($l; $e) else $e end)
         | if . > $n then $n else . end
       end]
    + [$n]
  | resolve;
def after_options($t; $i): $t.ao[$i] // $i;

# A word shaped like a shell assignment (`FOO=1`, `NAPPY_AGENT_ROLE=x`) -- these precede a real
# command without ending "command position" the way any other word would.
def is_assignment: test("^[A-Za-z_][A-Za-z0-9_]*=");

# Words that hand a command to something else to run, carrying "command position" forward past
# themselves and their own options: `bash`/`sh` run a script file, `env`/`timeout`/`xargs`/`nice`/
# `nohup`/`sudo`/`command`/`watch`/`stdbuf`/`caffeinate`/`time`/`exec`/`eval` run the word after
# their own options, whether written bare or as a path (`/usr/bin/env`), and
# after the shell's reserved words `do`, `then`, `else`, `elif`, `if`, `while`, `until`, `{` and `!`
# a command starts too -- `timeout` alone also takes one bare positional word (the duration) before
# its command, which `after_options` does not skip on its own since it is not `-`-prefixed. A
# command word matches in any case, as a path's last part (this Mac's disk is case-insensitive, so
# `ENV` runs env); a reserved word matches only as the shell spells it, since `If` is not `if`.
def wrapper_words: ["bash", "sh", "env", "timeout", "xargs", "nice", "nohup", "sudo", "command", "watch",
                     "stdbuf", "caffeinate", "time", "exec", "eval"];
def reserved_words: ["do", "then", "else", "elif", "if", "while", "until", "{", "!"];
def is_wrapper_word($x):
  ((reserved_words | index($x)) != null) or ((wrapper_words | index($x | last_part)) != null);

# For every word, the wrapper word it follows within its command (null before any), which owns
# the options read after it. One pass.
def wrapper_owners:
  [foreach .[] as $x (null; if $x | is_sep then null elif is_wrapper_word($x) then $x | last_part else . end)];

# For every index (already known to be in command position), the index of the real command word:
# skips any run of assignments and wrapper words (with the wrapper's own options, and `timeout`'s
# own duration argument), so `FOO=1 tools/release.sh`, `env FOO=1 tools/prune-merged.sh`, `timeout
# 60 tools/land-prs.sh` and `bash -x tools/prune-merged.sh` all land on the script name, not on the
# assignment, the option or the duration. A table, like `options_table`, and with levels each
# of those is skipped as a whole shell word (`FOO="a b"`, `timeout "1 m"`).
def command_table($ao; $g):
  . as $w
  | length as $n
  | ($g.lv) as $lv
  | ($g.ends) as $ends
  | def word_end($p):
      if $ends == null or $p >= $n then $p + 1
      else ($lv[$p]) as $l
        | if $l == 0 then $ends[$p].z elif $l == 1 then $ends[$p].o else $p + 1 end
      end;
    [range($n) as $i
     | $w[$i] as $x
     | if ($x | contains("=")) and ($x | is_assignment) then word_end($i)
       elif is_wrapper_word($x) then
         ($ao[word_end($i)] // $n) as $after
         | (if ($x | last_part) == "timeout" and $after < $n then word_end($after) else $after end)
       else $i end
     | if . > $n then $n else . end]
    + [$n]
  | resolve;
def command_word($t; $i): $t.cw[$i] // $i;

# `git <subcommand>`: push, and every subcommand that can create a commit under the invoking
# user's own name -- commit always; cherry-pick/revert/am/merge/rebase/pull unless they carry an
# abort-like or safe flag (`--abort`/`--quit` for cherry-pick/revert/am, `--abort`/`--no-commit`/
# `--ff-only` for merge, `--abort` for rebase, `--ff-only` for pull, which is the only shape of
# `git pull` that cannot make a commit of its own). Everything else (status, log, diff, fetch,
# branch, ...) is a read or a local-only change.
#
# The scan for one of those flags returns where it stopped either way (the next separator, or the
# end of the command), so the caller skips past everything already read rather than re-checking it
# one word at a time: many `git merge x` calls glued with no separator would each otherwise rescan
# the rest of the text, a cost quadratic in how many there are.
def segment_scan($w; $start; $n; $flags):
  {j: $start, found: false}
  | until(.j >= $n or ($w[.j] | is_sep);
      . as $s | .found = (.found or (($flags | index($w[$s.j])) != null)) | .j += 1)
  | {"end": .j, found: .found};

def detect_git($w; $t; $i; $n):
  if ($w[$i] | named("git")) | not then null
  else
    (after_options($t; $i + 1)) as $sub
    | if ($sub >= $n) or ($w[$sub] | is_sep) then null
      else
        ($w[$sub]) as $subcmd
        | if $subcmd == "push" then {next: ($sub + 1), reason: "git push"}
          elif $subcmd == "commit" then {next: ($sub + 1), reason: "git commit"}
          elif $subcmd | IN("cherry-pick", "revert", "am") then
            (segment_scan($w; $sub + 1; $n; ["--abort", "--quit"])) as $sc
            | {next: $sc.end, reason: (if $sc.found then null else ("git " + $subcmd) end)}
          elif $subcmd == "merge" then
            (segment_scan($w; $sub + 1; $n; ["--abort", "--no-commit", "--ff-only"])) as $sc
            | {next: $sc.end, reason: (if $sc.found then null else "git merge" end)}
          elif $subcmd == "rebase" then
            (segment_scan($w; $sub + 1; $n; ["--abort"])) as $sc
            | {next: $sc.end, reason: (if $sc.found then null else "git rebase" end)}
          elif $subcmd == "pull" then
            (segment_scan($w; $sub + 1; $n; ["--ff-only"])) as $sc
            | {next: $sc.end, reason: (if $sc.found then null else "git pull" end)}
          else null
          end
      end
  end;

# `gh api`'s own writes: an explicit non-GET method (`-X`/`--method`, attached or not, any case:
# `-XPOST`, `-X=POST`, `--method=post`), or any of `-f`/`-F`/`--input`/`--raw-field`/`--field`
# (attached or not: `-fk=v`, `--field=k=v`) with no explicit GET -- a field is what turns a call
# into a POST when no method is given, while under `-X GET` gh sends the fields as query
# parameters, so `gh api -X GET search/issues -f q=...` reads. Flags are found wherever they fall
# relative to the endpoint (`gh api -X PUT repos/o/r/pulls/1/merge` is exactly how gh itself
# accepts it), so the scan starts right after `api` itself rather than past its options, and a
# flag that takes a value consumes that value, so `-f k=v` before the endpoint is not mistaken
# for it.
#
# A `graphql` call always POSTs, so its own rule is different: it reads only when its query text
# is visible on the command line (a `query=` field whose value is written inline) and no word from
# the start of the call to the end of the whole command contains `mutation`. The check runs to the
# end of the command rather than over the call's own scanned words, so a quoted multi-line query
# (a first line that is a comment, `query=# resolve` then `mutation { ... }`, or a fragment written
# before the mutation) is covered even where a line inside it begins with a word the scan takes
# for the start of another command and stops at. Where the last
# word containing `mutation` sits is found once per command (`findings`' `$lm`), so this costs
# nothing per call. A later, unrelated `mutation` in the same command makes a false deny, the safe
# direction. A query read from a file (`-F query=@q.graphql`), from a shell
# variable or a command substitution (`query=$Q`, `query=$(cat q.graphql)`), a whole body from
# `--input`, or no `query=` field at all cannot be checked for the word, so each counts as a write.
#
# Whether a call is GraphQL is decided by its endpoint alone, the first word that is neither a
# flag nor a flag's value, so a field value that merely contains the word `graphql` never turns a
# REST write into a GraphQL read. Quotes are stripped before the split, so a query with spaces
# written before the endpoint leaves its later words to be taken for the endpoint and the call is
# denied -- the safe direction; writing the endpoint first (`gh api graphql -f query=...`) reads.
#
# A write whose endpoint ends in `/merge`, `/merges` or `/update-branch` (an optional trailing `/`
# or `?query` included), or that goes to a `/contents/` or `/git/refs` path, is a merge-type write
# (`is_merge_like`, below): the API form of `gh pr merge`/`update-branch`, a merge commit on a
# branch, a commit made through the contents API, or a branch created, moved or deleted through
# the git refs API. These patterns are checked against every non-option word of the call rather
# than the endpoint alone, since a header value such as `-H 'Accept: application/vnd.github+json'`
# splits into two words and would otherwise hide the real endpoint; the cost is a false deny for a
# reviewer whose comment body mentions such a path, which the deny message answers with
# `--input`.
#
# The scan runs to the next separator or the end of the command either way, win or lose, and a
# flag's value is consumed only when it is not itself a separator, so the caller skips past
# everything already read without ever skipping into the next command: many `gh api ...` calls
# glued with no separator would each otherwise rescan the rest of the text, a cost quadratic in
# how many there are. It never stops early on a bare `git`/`gh` word either, so an endpoint or
# flag value merely ending in `/gh` or `/git` is read in full rather than mistaken for the start of
# a new invocation.
#
# A scan that ran past a soft separator hands back where it crossed, so the caller still reads
# every word after the crossing for a write of its own; a `gh api` among those words is then
# scanned only up to its own next separator (`$bounded`), soft or hard, since everything past that
# is already part of the scan under way, which reads its flags as the first call's. Without that
# bound, every `gh api` mentioned after a quoted separator -- a line of a heredoc body in an
# unsure command, say, where every separator is soft -- would scan again to the same end, a cost
# quadratic in how many there are. A separator followed by a command start where git's and gh's
# own command table puts it (past assignments, wrapper words and reserved words: `do gh api`,
# `{ gh api`) ends the earlier scan, so the call after it is scanned in full. A later call that
# only the wrapper-options table reads as a command (`sh -c "gh api ..."`, `/usr/bin/env gh api`,
# `stdbuf -oL gh api`) stays inside the earlier scan instead, and its write flags count there: a
# field, `--input` or non-GET method past the crossing, with a `gh` or `api` word between the two,
# is a write even under the earlier call's own `-X GET` or GraphQL read.
# What the bound costs is a mention's flags past its own next separator (`echo gh api --jq '.a |
# .b' -f x=y` inside a script whose first call is a GraphQL read) counting only toward the call
# whose scan they fall in.
def gh_api_field_flag: IN("-f", "-F", "--raw-field", "--field");
def gh_api_value_flag: IN("-H", "--header", "--hostname", "-p", "--preview", "-q", "--jq", "-t",
  "--template", "--cache");

# Folds one `k=v` field value into the scan state: `query=` with a value written inline makes the
# query visible; `query=` whose value is empty, from a file (`@`) or a shell expansion (`$`) hides it.
def gh_api_field_value($v):
  if $v | test("(?i)^query=") then
    ($v | sub("(?i)^query="; "")) as $q
    | if ($q == "") or ($q | startswith("@")) or ($q | contains("$")) then .query_hidden = true
      else .query_visible = true end
  else . end;

def write_tool_names: ["release.sh", "prune-merged.sh", "land-prs.sh", "update-pr.sh"];

# Whether the command that would start at index $j (past any assignment or wrapper word) is one
# this hook detects: git, gh, the identity wrapper or a pushing script. A `gh api` scan stops at a
# soft separator followed by one, so glued calls inside one quoted `bash -c "..."` are each
# scanned once rather than each to the end of the string.
#
# The command word is where git's and gh's own command table puts it (`cw`), and, when the reading
# is unsure, the word-by-word one too (`.tp`). The wrapper-options table (`cw2`) is not read here:
# after a quoted separator inside a call's own argument (`--jq '.x; sh -c git'`) it would end the
# call's scan before its later flags. A call that only `cw2` sees as a command start (the script
# after `sh -c "..."`, `/usr/bin/env gh api ...`) stays inside the earlier scan, where its write
# flags count as late (see `gh_api_method`).
def command_positions($t; $j):
  [$t.cw[$j] // $j] + (if $t.tp == null then [] else [$t.tp.cw[$j] // $j] end);
def starts_command($w; $t; $j; $n):
  any(command_positions($t; $j)[];
      . < $n
      and ($w[.] | last_part as $lp
           | ($lp | IN("git", "gh", "agent-identity.py")) or ((write_tool_names | index($lp)) != null)));

# Records a method; past a soft separator, a GET is ignored, since it may belong to another command
# inside the same quoted string, and taking it would turn this call's write into a read. For the
# same reason a field past a soft separator with a `gh` or `api` word between the two
# (`late_field`), which may be another call's flag, counts as a write even under a GET; a field
# right after a quoted `--jq '.a | .b'` is still this call's and reads, and so does a GraphQL
# read's variable after one. A non-GET method in the same place is late too, so under a GraphQL
# read, whose own method is always POST, a late field or method is a write. The word `api` as a
# word of its own inside a quoted argument reads as another call's too, so a field after it
# denies: inside a `--jq` filter's own string (`select(test("api"))`), and inside a GraphQL query
# (`query='query($n:Int!){ repository(owner: "a", name: "api") { ... } }' -F n=1`). Both are false
# denies, the safe direction.
def gh_api_method($m):
  if (.crossed_at != null) and (($m | ascii_downcase) == "get") then .
  else .method = $m | (if .other_call then .late_field = true else . end) end;

def detect_gh_api($w; $t; $start; $n; $lm; $bounded):
  {i: $start, method: null, field: false, late_field: false, other_call: false,
   endpoint: null,
   merge_type: false,
   query_visible: false, query_hidden: false, crossed_at: null, cont: false}
  | (until(.i >= $n or ($w[.i] | is_hard_sep)
          or ($bounded and ($w[.i] | is_sep))
          or (($w[.i] == "\u0001") and starts_command($w; $t; .i + 1; $n));
      . as $s
      | ($w[$s.i]) as $x
      | ($w[$s.i + 1] // null) as $nx
      | ($nx != null and (($nx | is_sep) | not)) as $has_value
      | (if $x | startswith("-") then .cont = false else . end)
      | if $x == "\u0001" then
          .crossed_at = (.crossed_at // .i) | .cont = true | .i += 1
        elif $x | IN("-X", "--method") then
          (if $has_value then gh_api_method($nx) | .i += 2 else .method = "" | .i += 1 end)
        elif $x | startswith("--method=") then gh_api_method($x | ltrimstr("--method=")) | .i += 1
        elif $x | test("^(?i)-X=?.+") then gh_api_method($x | sub("^(?i)-X=?"; "")) | .i += 1
        elif $x | gh_api_field_flag then
          .field = true | .late_field = (.late_field or .other_call)
          | (if $has_value then gh_api_field_value($nx) | .i += 2 else .i += 1 end)
        elif $x | test("^--(field|raw-field)=") then
          .field = true | .late_field = (.late_field or .other_call)
          | gh_api_field_value($x | sub("^--(field|raw-field)="; "")) | .i += 1
        elif $x | test("^-[fF].+") then
          .field = true | .late_field = (.late_field or .other_call)
          | gh_api_field_value($x | .[2:]) | .i += 1
        elif $x == "--input" then
          .field = true | .late_field = (.late_field or .other_call) | .query_hidden = true
          | (if $has_value then .i += 2 else .i += 1 end)
        elif $x | startswith("--input=") then
          .field = true | .late_field = (.late_field or .other_call) | .query_hidden = true
          | .i += 1
        elif $x | gh_api_value_flag then (if $has_value then .i += 2 else .i += 1 end)
        elif $x | startswith("-") then .i += 1
        else
          (if (.endpoint == null) and (.cont | not) then .endpoint = $x else . end)
          # Past a crossing, a `gh` or `api` word may start another call's flags.
          | (if .crossed_at != null and ($x | last_part | IN("gh", "api")) then .other_call = true
             else . end)
          | (if ($x | contains("/"))
                and (($x | test("(?i)/(merges?|update-branch)/?(\\?.*)?$")) or ($x | test("(?i)/contents/"))
                     or ($x | test("(?i)/git/refs(/|$)")))
             then .merge_type = true else . end)
          | .i += 1
        end)
  | .resume = (.crossed_at // .i)) as $r
  | (($r.method != null) and (($r.method | ascii_downcase) == "get")) as $is_get
  | if ($r.endpoint // "") | test("(?i)(^|/)graphql$") then
      (if $lm >= $start then {next: $r.resume, reason: "gh api graphql mutation"}
       elif $r.query_hidden or ($r.query_visible | not)
       then {next: $r.resume, reason: "gh api graphql with a query not written inline"}
       elif $r.late_field then {next: $r.resume, reason: "gh api"}
       else {next: $r.resume, reason: null} end)
    elif $is_get and ($r.late_field | not) then {next: $r.resume, reason: null}
    elif ($r.method != null) or $r.field then
      {next: $r.resume, reason: (if $r.merge_type then "gh api merge-type" else "gh api" end)}
    else {next: $r.resume, reason: null}
    end
  | .scan_end = (if $r.crossed_at == null then null else $r.i end);

# Every `gh` noun writes unless its verb is on one shared list of reads (`view`, `list`, `status`,
# `diff`, `checks`, `checkout` -- `gh pr`'s own local-only checkout -- `watch`, `download`,
# `clone`, `token`): every noun, not only `pr`/`issue`/`release`, so `gh workflow run`, `gh run
# rerun`/`cancel`, `gh repo edit`, `gh label`/`secret`/`variable`/`cache`/`gist` writes all deny
# too, the same fail-safe way a verb this list has never heard of does. `gh browse` and `gh
# search` (a noun whose own verbs -- `prs`, `issues`, `repos`, `code`, `commits` -- are never on
# the shared list) are read nouns whole, with no verb of their own to check; `gh api` is
# `detect_gh_api`'s. A noun or verb position that lands on a separator or the end of the command
# (`gh status | head`, `gh --version && gh auth status`) has no noun/verb there at all, not the
# separator itself, so it never becomes part of a denial reason.
def generic_reads: ["view", "list", "status", "diff", "checks", "checkout", "watch", "download", "clone", "token"];
def read_only_nouns: ["browse", "search"];
def detect_gh($w; $t; $i; $n; $lm; $bounded):
  if ($w[$i] | named("gh")) | not then null
  else
    (after_options($t; $i + 1)) as $noun_i
    | if ($noun_i >= $n) or ($w[$noun_i] | is_sep) then null
      else
        ($w[$noun_i]) as $noun
        | if read_only_nouns | index($noun) then null
          elif $noun == "api" then detect_gh_api($w; $t; $noun_i + 1; $n; $lm; $bounded)
          else
            (after_options($t; $noun_i + 1)) as $verb_i
            | if ($verb_i >= $n) or ($w[$verb_i] | is_sep) then null
              else
                ($w[$verb_i]) as $verb
                | if $verb | ascii_downcase | IN(generic_reads[]) then null
                  else {next: ($verb_i + 1), reason: ("gh " + $noun + " " + $verb)}
                  end
              end
          end
      end
  end;

# A `tools/*.sh` entry point whose own body pushes or posts without saying so in the words this
# hook can see (see the header's own list and how it was found) -- guarded only in command
# position (`command_word` above: the first word of a command, past any assignment or wrapper
# word, or right after that literal `--`), never where its name is merely a read's argument (`cat
# tools/release.sh`, `git log -- tools/land-prs.sh`, `git show HEAD:tools/release.sh`, `rg ...
# tools/update-pr.sh`). `release.sh` only tags and pushes when its own second positional argument
# is literally `push` (see its usage); `land-prs.sh` and `update-pr.sh` both skip every GitHub
# write under `--dry-run`; `prune-merged.sh` has no dry-run shape and is a write whenever it runs
# at all.
#
# Whether a `push` or a `--dry-run` follows before the next separator is read from a table built
# in one pass from the end of the command, rather than scanned again from each script name: a
# wrapper starts a new command position, so `tools/release.sh ... run <role> -- tools/release.sh
# ...` repeated would otherwise scan to the separator from every one of them.
def script_table:
  [foreach (reverse | .[]) as $y ({push: false, dry: false};
     if $y | is_sep then {push: false, dry: false}
     else .push = (.push or $y == "push") | .dry = (.dry or $y == "--dry-run") end)]
  | reverse;
def script_is_write($t; $base; $start):
  ($t.sw[$start] // {push: false, dry: false}) as $scan
  | if $base == "release.sh" then $scan.push
    elif ($base == "land-prs.sh") or ($base == "update-pr.sh") then ($scan.dry | not)
    else true
    end;
def detect_tool($w; $t; $i; $cmd_pos):
  if $cmd_pos | not then null
  else
    ($w[$i] | last_part) as $base
    | if (write_tool_names | index($base)) == null then null
      elif script_is_write($t; $base; $i + 1) then {next: ($i + 1), reason: ("tools/" + $base)}
      else null
      end
  end;

# `tools/agent-identity.py run [--repo OWNER/REPO] <role> -- ...`, with or without a `uv run
# python`/`python3` in front (irrelevant here -- only the three words right after `run` matter):
# the role and the index right after that literal `--`, everything from which is the wrapped
# command and exempt (a reviewer role's own push or merge aside -- see reviewer_roles below), and
# whether that `--` sat inside quotes (`inner`: the wrapper is part of a quoted script, so its
# exemption ends at the script's own next separator -- see mark_soft_separators).
def detect_wrapper($w; $t; $i; $n):
  if ($w[$i] | named("agent-identity.py")) and ($w[$i + 1] == "run") then
    (after_options($t; $i + 2)) as $role_i
    | if ($role_i < $n) and ($w[$role_i + 1] | IN("--", "--\u0002")) then
        {next: ($role_i + 2), role: $w[$role_i], inner: ($w[$role_i + 1] != "--")}
      else null end
  else null
  end;

# A reviewer identity never pushes or merges through this tool, whatever GitHub's own permission
# allows (contents:write, since a reviewer's APPROVE needs it -- see _REVIEWER_PERMISSIONS's own
# comment): a coder identity, or claude-orchestrator on a pull request with no code changes, is the
# one that pushes and merges. Reviewer roles are named, not
# pattern-matched on "-reviewer": a role this list does not know (a typo, a role the brief never
# named) is not specially blocked here -- `tools/agent-identity.py` itself refuses to mint a token
# for a name outside its own ROLE_NAMES, which is the actual enforcement for an unknown role, not
# this check.
def reviewer_roles: ["claude-reviewer", "codex-reviewer"];
def is_push_like($reason): ($reason == "git push") or ($reason | startswith("tools/"));
def is_merge_like($reason):
  ($reason == "gh pr merge") or ($reason == "gh pr update-branch") or ($reason == "gh api merge-type");

# One pass over the word array: a hard separator resets the current command's exemption, and so
# does a soft one when the wrapper stood inside quotes (`inner`) or the reading is `$unsure` (every
# separator is soft then, and every one ends the exemption); any separator recomputes
# command position for the next word (`command_word`, from right after the separator); the wrapper
# pattern sets where its own command's exemption starts (and which role it names), and recomputes
# command position for the wrapped command the same way; anything else is checked against the
# three detectors, and a hit before the exemption (or with none active) is a finding -- as is a
# push- or merge-like hit inside a reviewer's own wrapper. A hit with no reason (a gh api/git
# command read as safe) is not a finding, but its own `next` still lets the pass skip everything
# it already scanned. `scanned_to` is where the last `gh api` scan that crossed a soft separator
# ended: a `gh api` before it is scanned bounded (see `detect_gh_api`). Every run of options,
# assignments and wrapper words, and every script's `push`/`--dry-run`, is read from the tables in
# `$t`, built once, so no word is walked from more than once however the command is built.
# The first of two hits that names a write, else the first; the second is computed only when the
# first names none.
def either(a; b):
  a as $x
  | if $x != null and $x.reason != null then $x
    else (b as $y | if $y != null and $y.reason != null then $y else $x end) end;
#
# Command position is where any of up to four tables puts it: past a wrapper, its options read
# as git's and gh's (`cw`) and as the wrapper's own (`cw2`), each grouped by shell word (`$t`)
# and, when the reading is unsure, also word by word (`$tp`).
def command_words($t; $tp; $i):
  [command_word($t; $i)]
  + (if $t.cw2 == null then [] else [$t.cw2[$i] // $i] end)
  + (if $tp == null then []
     else [command_word($tp; $i)] + (if $tp.cw2 == null then [] else [$tp.cw2[$i] // $i] end) end);
def findings($w; $levels; $unsure):
  # Levels that are all 0 group nothing, and the plain reading would be the same one again.
  (if $levels | any(. > 0) then $levels else null end) as $lv
  | ($w | length) as $n
  | ([range(0; $n) | select($w[.] | test("(?i)mutation"))] | last // -1) as $lm
  # A command with no wrapper word needs no table of wrapper options.
  | (if any($w[]; is_wrapper_word(.)) then $w | wrapper_owners else null end) as $owners
  | (if $lv == null then null else {lv: $lv, ends: word_ends($lv)} end) as $g
  | ($w | options_table($g; null)) as $ao
  | {ao: $ao, cw: ($w | command_table($ao; $g)),
     cw2: (if $owners == null then null else $w | command_table($w | options_table($g; $owners); $g) end),
     sw: ($w | script_table)} as $t
  | (if $unsure and $lv != null
     then ($w | options_table(null; null)) as $ao0
       | $t | .ao = $ao0 | .cw = ($w | command_table($ao0; null))
       | .cw2 = (if $owners == null then null
                 else $w | command_table($w | options_table(null; $owners); null) end)
     else null end) as $tp
  | ($t | .tp = $tp) as $t
  | {i: 0, wrap_from: null, wrap_role: null, wrap_inner: false, wrapped: false,
     cmd_words: command_words($t; $tp; 0), out: [], reviewer_push: false, scanned_to: -1}
  | until(.i >= $n;
      . as $state
      | ($w[$state.i]) as $x
      | (detect_wrapper($w; $t; $state.i; $n)
         // (if $tp == null then null else detect_wrapper($w; $tp; $state.i; $n) end)) as $wrap
      | (($state.cmd_words | index($state.i)) != null) as $cmd_pos
      | if $x | is_sep then
          $state
          | (if $unsure or ($x | is_hard_sep) or .wrap_inner
             then .wrap_from = null | .wrap_role = null | .wrap_inner = false else . end)
          | .cmd_words = command_words($t; $tp; $state.i + 1)
          | .i += 1
        elif $wrap != null then
          $state | .wrap_from = $wrap.next | .wrap_role = $wrap.role | .wrap_inner = $wrap.inner
          | .wrapped = true
          | .cmd_words = command_words($t; $tp; $wrap.next)
          | .i += 1
        else
          ($state.i < $state.scanned_to) as $bounded
          | ($t.ao[$state.i + 1]) as $a1
          | (either(detect_git($w; $t; $state.i; $n);
                    if $tp == null or $tp.ao[$state.i + 1] == $a1 then null
                    else detect_git($w; $tp; $state.i; $n) end)
             // either(detect_gh($w; $t; $state.i; $n; $lm; $bounded);
                       if $tp == null or ($tp.ao[$state.i + 1] == $a1 and $w[$a1] == "api") then null
                       else detect_gh($w; $tp; $state.i; $n; $lm; $bounded) end)
             // detect_tool($w; $t; $state.i; $cmd_pos)) as $hit
          | if $hit == null then $state | .i += 1
            elif $hit.reason == null then $state | .i = $hit.next | .scanned_to = ($hit.scan_end // .scanned_to)
            else
              ($state
               | .scanned_to = ($hit.scan_end // .scanned_to)
               | if (.wrap_from != null) and ($state.i >= .wrap_from) then
                   (if (is_push_like($hit.reason) or is_merge_like($hit.reason))
                       and ((reviewer_roles | index($state.wrap_role)) != null)
                    then .out += [$hit.reason] | .reviewer_push = true
                    else . end)
                 else .out += [$hit.reason] end
               | .i = $hit.next)
            end
        end)
  | {out, reviewer_push, wrapped};

# A command longer than `too_long` is not read at all: the character pass and the word scans are
# linear, but a dense 200 KB heredoc commit takes several seconds, and a hook that runs past its
# 10-second timeout does not block the call in either Claude Code or Codex -- it fails open. 64 KB
# is about three times the longest pull request body this repository has, and even at its densest
# (a separator on every character) is decided in about a quarter of the timeout.
#
# Over it, the check is deliberately dumb and fast rather than a reading of the shell: with every
# backslash-newline pair, lone backslash, quote character and `$` taken out (however the shell
# would have joined, quoted or expanded them -- `g$''it` and `g$""it` are `git` to bash), a command
# in which `git`, `gh` or a pushing script's name appears anywhere, even inside another word, is
# denied with the hint to put the long text in a file; one in which none appears cannot name a
# write and is allowed. A newline on its own is not taken out, since the shell joins two lines
# only at a backslash: prose with a line ending in `g` before one starting with `it` holds no
# `git`.
# The characters are skipped by the regex itself (`(?:\\\n|[\\"'$])*` between every two letters of
# a name) rather than removed from a copy, so the check is one linear regex search: every name
# starts with a letter outside that set, so a run of skipped characters is scanned once per letter
# that precedes it. Over `hard_cap` (1 MB) a command is denied without even that, so the hook's
# own cost stays well under a second whatever it is given.
def too_long: 65536;
def hard_cap: 1048576;
def names_a_write_tool:
  "(?:\\\\\n|[\\\\\"'$])*" as $skip
  | "(?i)" + (["git", "gh", "release.sh", "prune-merged.sh", "land-prs.sh", "update-pr.sh"]
             | map(split("") | map(if . == "." then "\\." else . end) | join($skip))
             | join("|"));

if (.tool_name | IN("Bash", "Monitor")) | not then empty else
  (.tool_input.command // "")
  | (if type == "string" then . elif type == "array" then map(tostring) | join(" ") else "" end)
  | if length > hard_cap then
      {out: ["the whole command: over 1 MB, not read at all"],
       reviewer_push: false, wrapped: false, too_long: true}
    elif length > too_long then
      if test(names_a_write_tool)
      then {out: ["the whole command: over 64 KB and naming git, gh or a pushing script"],
            reviewer_push: false, wrapped: false, too_long: true}
      else empty end
    else
      (swap(">&"; ">") | swap("<&"; "<") | swap("&>"; ">")) as $raw
      | ($raw | swap("${IFS}"; " ") | swap("$IFS"; " ")) as $bare
      # With no quote, backslash or `#` in it, the character pass has nothing to track: only an
      # unquoted comma or bracket becomes glue.
      | ($bare
         | if test("['\"\\\\#]") then mark_soft_separators
           else swap(","; "\u0004") | swap("["; "\u0004") | swap("]"; "\u0004") end) as $marked
      | (($marked | contains("\u0003"))
         or ($bare | drop("\\\n") | test("\\$\\(|`|<<|\\$\\{|\\$\\$'"))) as $unsure
      | ($marked | drop("\u0003") | split_words | leveled_parts) as $parts
      | ($parts | map(.w) | if $unsure then map(if is_sep then "\u0001" else . end) else . end) as $w
      | (findings($w; $parts | map(.c); $unsure)) as $result
      | if ($result.out | length) == 0 then empty else $result end
    end
end

JQ

command -v jq >/dev/null 2>&1 || exit 0
if ! result=$(jq -c "$check_program" 2>/dev/null); then
	flagged="(the guard's own jq program failed on this command, so it could not be checked)"
	reviewer_push=false
	wrapped=false
	too_long=false
elif [ -z "$result" ]; then
	exit 0
else
	flagged=$(printf '%s' "$result" | jq -r '.out | join("; ")')
	reviewer_push=$(printf '%s' "$result" | jq -r '.reviewer_push')
	wrapped=$(printf '%s' "$result" | jq -r '.wrapped')
	too_long=$(printf '%s' "$result" | jq -r '.too_long // false')
fi

# The hint for a long text: a file the command reads is not text the hook has to read.
file_hint="Write the text to a file first and pass the file (git commit -F file, gh pr \
create/comment --body-file file, gh api -F body=@file or --input file), then run a short command."

if [ "$too_long" = "true" ]; then
	reason="The write guard denies this command without reading it ($flagged): over 64 KB, a \
command that names git, gh or a pushing tools/ script anywhere is denied, and over 1 MB any command \
is, because a hook that cannot finish inside its timeout would let the command through unchecked. \
$file_hint See .claude/hooks/github-write-guard.sh."
elif [ "$reviewer_push" = "true" ]; then
	reason="This command ($flagged) runs as a reviewer identity (claude-reviewer or codex-reviewer), \
but reviewers never push or merge. Wrap it in \
'uv run python tools/agent-identity.py run claude-coder -- <command>' (or codex-coder) instead, \
or claude-orchestrator when the pull request has no code changes. \
If this is a comment or review whose own text only mentions a path such as /merge, /contents/ or \
/git/refs, send the body from a file with --input (or -F body=@file) so its words are not read as \
the endpoint. See committing and pr-review."
else
	reason="This command writes to GitHub ($flagged) outside any agent identity. A write is a git \
push; a commit-making git verb (commit, cherry-pick/revert/am, merge/rebase past --abort, pull \
past --ff-only); any gh noun's write verb (every noun, not only pr/issue/release), gh api with a \
non-GET method or a field outside -X GET, or a GraphQL call whose query is a mutation or is not \
written inline (a file, a variable, --input); or a pushing/posting tools/ script in command \
position. It runs through 'uv run python tools/agent-identity.py run <role> -- <command>' instead \
-- in Claude Code claude-coder for a pull request that changes code, claude-orchestrator for an \
issue or a pull request with no code changes, claude-reviewer for a review; in Codex codex-coder, \
or codex-reviewer for a review -- never directly. Check first with 'uv run python tools/agent-identity.py status <role>'; if it reports \
the role not usable, stop and tell the player rather than running this directly. An admin action \
no bot identity can make (a repository ruleset, a GitHub App's own permissions) is the player's to \
do directly in GitHub's own settings, never something to wrap and retry. See committing and \
pr-review, and .claude/hooks/github-write-guard.sh for the current list of what counts as a write."
	if [ "$wrapped" = "true" ]; then
		reason="$reason If this command is already wrapped, the write named here is probably a \
mention in text the hook reads as commands: a heredoc or \$(...) body (a commit message, a PR \
body) makes every separator end the wrapper's reach, so a later line that names a write reads as \
unwrapped. $file_hint"
	fi
fi

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
exit 0
