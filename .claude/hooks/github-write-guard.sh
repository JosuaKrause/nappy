#!/usr/bin/env bash
# Denies a command that writes to GitHub unless it runs through an agent's own identity.
#
# CLAUDE.md's committing/pr-review skills make this mandatory: a coding agent commits, pushes and
# opens its pull request as its own GitHub identity (`claude-coder`/`codex-coder`), a review agent
# posts its review as its own (`claude-reviewer`/`codex-reviewer`), and when `tools/agent-identity.py
# status <role>` says a role is not usable, the session stops and tells the player rather than
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
# `docs/decisions/2026-09-27-tall-egret.md`'s "Accepted gaps" paragraph.
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
# word's own options -- `bash`/`sh`/`env`/`timeout`/`xargs`/`nice`/`nohup`/`sudo`/`command`/`watch`,
# `timeout` alone also taking one bare duration -- never where its name is merely a read's argument
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
# claude-reviewer --`/`run codex-reviewer --`, with a message naming the coder identity to use
# instead. A GraphQL mutation is not refused by name: `resolveReviewThread`, which a reviewer
# needs, is one, so `mergePullRequest` or `enablePullRequestAutoMerge` under a reviewer role is an
# accepted gap. A role this hook
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
# echo, a commit message, a code comment) denies exactly like a real invocation would. Quotes are
# still read for one thing first: a separator inside them (`--jq '.a | .b'`, `-f body='a; b'`, a
# `(` in an inline GraphQL query) is soft -- it still splits words, so a command inside `bash -c
# "..."` is still found, but it neither ends a `gh api` call's flags, so a write flag after the
# quoted argument is seen, nor ends the exemption of a wrapper standing outside the quotes, so
# `run <role> -- bash -c "a; b"` covers the whole script it runs. A wrapper inside the quotes is
# told apart by its quoted `--`, and its exemption ends at the next separator, soft or hard; a
# wrapper inside a script that an outer wrapper already covers (`run <role> -- bash -c "run
# <role> -- a; b"`) is then a false deny for `b`, the safe direction. So is a heredoc body with an
# odd number of apostrophes: the heredoc is not tracked, so the quote it opens stays open and a
# later wrapper on another line reads as an inner one, whose exemption ends at the next separator.
# A `--` spelled with escapes inside the quotes (`\"--\"`, `\-\-`) is not marked, so that
# wrapper reads as an outer one -- an accepted gap (see the list above). The one
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
# tracking which quote is open (0 none, 1 single, 2 double, 3 `$'...'`, where a backslash escapes
# as it does outside quotes and in double quotes, but not in single quotes, and `\n` is a newline,
# so a soft separator; 4 a `#` comment) and the two characters before the last, so a `--` is marked
# when the character that ends it arrives: the two before are `-`, the one before those starts a
# word, and a quote is still open.
#
# An unquoted, unescaped `#` that starts a word (nothing, whitespace or `;`/`&`/`|`/`(`/`)`/a
# newline before it) opens a comment that the next newline closes, as the shell reads it: quotes
# and backslashes inside it change nothing, so an apostrophe in `# the player's words` never opens
# a quote that would soften every later separator and stretch a wrapper's exemption to the end of
# the command. Its words are still split and read, so a write named in a comment denies as a
# mention, and a separator in it stays hard (`# fine; git push` after a wrapped command denies).
def sep_codepoints: [59, 38, 124, 40, 41, 96, 10];
def word_edge_codepoints: [32, 9, 10, 34, 39];
def comment_start_codepoints: [32, 9, 10, 59, 38, 124, 40, 41];
def mark_soft_separators:
  [foreach explode[] as $c ({q: 0, esc: false, prev: null, p2: null, p3: null, emit: []};
      .prev as $prev
      | (if .q == 4 then [$c]
         elif .esc and .q == 3 and $c == 110 then [32, 1, 32]
         elif (.esc or .q != 0) and ((sep_codepoints | index($c)) != null) then [32, 1, 32]
         else [$c] end) as $out
      | .p3 as $p3
      | ((.esc | not) and .q != 0 and .q != 4 and .prev == 45 and .p2 == 45
         and ($p3 == null or ((word_edge_codepoints | index($p3)) != null))
         and (((word_edge_codepoints + sep_codepoints) | index($c)) != null)) as $quoted_dashes
      | if .q == 4 then (if $c == 10 then .q = 0 else . end) | .emit = $out
        elif .esc then .esc = false | .emit = $out
        elif $c == 92 and .q != 1 then .esc = true | .emit = [$c]
        elif .q == 0 and $c == 35
             and ($prev == null or ((comment_start_codepoints | index($prev)) != null))
        then .q = 4 | .emit = [$c]
        elif .q == 0 and $c == 39 then .q = (if .prev == 36 then 3 else 1 end) | .emit = [$c]
        elif .q == 0 and $c == 34 then .q = 2 | .emit = [$c]
        elif (.q == 1 or .q == 3) and $c == 39 then .q = 0 | .emit = [$c]
        elif .q == 2 and $c == 34 then .q = 0 | .emit = [$c]
        else .emit = $out
        end
      | (if $quoted_dashes then .emit = [2] + .emit else . end)
      | .p3 = .p2 | .p2 = .prev | .prev = $c;
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
# next separator, soft or hard.
def words:
  mark_soft_separators
  | swap("$'"; "'")
  | drop("\\") | drop("\"") | drop("'")
  | swap("\t"; " ") | swap(","; " ") | swap("["; " ") | swap("]"; " ")
  | swap(";"; " ; ") | swap("&"; " & ") | swap("|"; " | ")
  | swap("("; " ( ") | swap(")"; " ) ") | swap("`"; " ` ") | swap("\n"; " \n ")
  | split(" ") | map(select(length > 0));

def is_sep: IN(";", "&", "|", "(", ")", "`", "\n", "\u0001");
def is_hard_sep: IN(";", "&", "|", "(", ")", "`", "\n");

# Global options taking a separate argument -- git's, gh's and agent-identity.py run's own
# --repo alike, one small list, fail-safe: an option not on it is skipped as one word, so an
# unfamiliar flag can never hide the word after it (the same call git-grep-guard.sh's
# after_options makes for git).
def takes_argument:
  IN("-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--config-env",
     "--attr-source", "-R", "--repo", "--hostname");

# From index $i, the index of the first word in $w that is not a leading `-`-prefixed option (or
# that option's own separate argument).
def after_options($w; $i):
  {i: $i}
  | until(.i >= ($w | length) or (($w[.i] | startswith("-")) | not);
      if $w[.i] | takes_argument then .i += 2 else .i += 1 end)
  | .i;

# A word shaped like a shell assignment (`FOO=1`, `NAPPY_AGENT_ROLE=x`) -- these precede a real
# command without ending "command position" the way any other word would.
def is_assignment: test("^[A-Za-z_][A-Za-z0-9_]*=");

# Words that hand a command to something else to run, carrying "command position" forward past
# themselves and their own options: `bash`/`sh` run a script file, `env`/`timeout`/`xargs`/`nice`/
# `nohup`/`sudo`/`command`/`watch` run the word after their own options -- `timeout` alone also
# takes one bare positional word (the duration) before its command, which `after_options` does not
# skip on its own since it is not `-`-prefixed.
def wrapper_words: ["bash", "sh", "env", "timeout", "xargs", "nice", "nohup", "sudo", "command", "watch"];
def is_wrapper_word($x): (wrapper_words | index($x)) != null;

# From index $i (already known to be in command position), the index of the real command word:
# skips any run of assignments and wrapper words (with the wrapper's own options, and `timeout`'s
# own duration argument), so `FOO=1 tools/release.sh`, `env FOO=1 tools/prune-merged.sh`, `timeout
# 60 tools/land-prs.sh` and `bash -x tools/prune-merged.sh` all land on the script name, not on the
# assignment, the option or the duration.
def command_word($w; $i; $n):
  {i: $i, go: true}
  | until((.i >= $n) or (.go | not);
      ($w[.i]) as $x
      | if $x | is_assignment then .i += 1
        elif is_wrapper_word($x) then
          (after_options($w; .i + 1)) as $after
          | .i = (if ($x | last_part) == "timeout" and $after < $n then $after + 1 else $after end)
        else .go = false
        end)
  | .i;

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

def detect_git($w; $i; $n):
  if ($w[$i] | named("git")) | not then null
  else
    (after_options($w; $i + 1)) as $sub
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
def starts_command($w; $j; $n):
  (command_word($w; $j; $n)) as $k
  | ($k < $n)
    and ($w[$k] | last_part as $lp
         | ($lp | IN("git", "gh", "agent-identity.py")) or ((write_tool_names | index($lp)) != null));

# Records a method; past a soft separator, a GET is ignored, since it may belong to another command
# inside the same quoted string, and taking it would turn this call's write into a read.
def gh_api_method($m):
  if (.crossed_at != null) and (($m | ascii_downcase) == "get") then . else .method = $m end;

def detect_gh_api($w; $start; $n; $lm):
  {i: $start, method: null, field: false, endpoint: null, merge_type: false,
   query_visible: false, query_hidden: false, crossed_at: null, cont: false}
  | (until(.i >= $n or ($w[.i] | is_hard_sep)
          or (($w[.i] == "\u0001") and starts_command($w; .i + 1; $n));
      . as $s
      | ($w[$s.i]) as $x
      | ($w[$s.i + 1] // null) as $nx
      | ($nx != null and (($nx | is_sep) | not)) as $has_value
      | (if $x | startswith("-") then .cont = false else . end)
      | if $x == "\u0001" then .crossed_at = (.crossed_at // .i) | .cont = true | .i += 1
        elif $x | IN("-X", "--method") then
          (if $has_value then gh_api_method($nx) | .i += 2 else .method = "" | .i += 1 end)
        elif $x | startswith("--method=") then gh_api_method($x | ltrimstr("--method=")) | .i += 1
        elif $x | test("^(?i)-X=?.+") then gh_api_method($x | sub("^(?i)-X=?"; "")) | .i += 1
        elif $x | gh_api_field_flag then
          .field = true
          | (if $has_value then gh_api_field_value($nx) | .i += 2 else .i += 1 end)
        elif $x | test("^--(field|raw-field)=") then
          .field = true | gh_api_field_value($x | sub("^--(field|raw-field)="; "")) | .i += 1
        elif $x | test("^-[fF].+") then .field = true | gh_api_field_value($x | .[2:]) | .i += 1
        elif $x == "--input" then
          .field = true | .query_hidden = true | (if $has_value then .i += 2 else .i += 1 end)
        elif $x | startswith("--input=") then .field = true | .query_hidden = true | .i += 1
        elif $x | gh_api_value_flag then (if $has_value then .i += 2 else .i += 1 end)
        elif $x | startswith("-") then .i += 1
        else
          (if (.endpoint == null) and (.cont | not) then .endpoint = $x else . end)
          | (if ($x | test("(?i)/(merges?|update-branch)/?(\\?.*)?$")) or ($x | test("(?i)/contents/"))
                or ($x | test("(?i)/git/refs(/|$)"))
             then .merge_type = true else . end)
          | .i += 1
        end)
  | .resume = (.crossed_at // .i)) as $r
  | (($r.method != null) and (($r.method | ascii_downcase) == "get")) as $is_get
  | if ($r.endpoint // "") | test("(?i)(^|/)graphql$") then
      (if $lm >= $start then {next: $r.resume, reason: "gh api graphql mutation"}
       elif $r.query_hidden or ($r.query_visible | not)
       then {next: $r.resume, reason: "gh api graphql with a query not written inline"}
       else {next: $r.resume, reason: null} end)
    elif $is_get then {next: $r.resume, reason: null}
    elif ($r.method != null) or $r.field then
      {next: $r.resume, reason: (if $r.merge_type then "gh api merge-type" else "gh api" end)}
    else {next: $r.resume, reason: null}
    end;

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
def detect_gh($w; $i; $n; $lm):
  if ($w[$i] | named("gh")) | not then null
  else
    (after_options($w; $i + 1)) as $noun_i
    | if ($noun_i >= $n) or ($w[$noun_i] | is_sep) then null
      else
        ($w[$noun_i]) as $noun
        | if read_only_nouns | index($noun) then null
          elif $noun == "api" then detect_gh_api($w; $noun_i + 1; $n; $lm)
          else
            (after_options($w; $noun_i + 1)) as $verb_i
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
def script_is_write($w; $base; $start; $n):
  ({j: $start, push: false, dry: false}
   | until(.j >= $n or ($w[.j] | is_sep);
       $w[.j] as $y
       | if $y == "push" then .push = true | .j += 1
         elif $y == "--dry-run" then .dry = true | .j += 1
         else .j += 1 end)) as $scan
  | if $base == "release.sh" then $scan.push
    elif ($base == "land-prs.sh") or ($base == "update-pr.sh") then ($scan.dry | not)
    else true
    end;
def detect_tool($w; $i; $n; $cmd_pos):
  if $cmd_pos | not then null
  else
    ($w[$i] | last_part) as $base
    | if (write_tool_names | index($base)) == null then null
      elif script_is_write($w; $base; $i + 1; $n) then {next: ($i + 1), reason: ("tools/" + $base)}
      else null
      end
  end;

# `tools/agent-identity.py run [--repo OWNER/REPO] <role> -- ...`, with or without a `uv run
# python`/`python3` in front (irrelevant here -- only the three words right after `run` matter):
# the role and the index right after that literal `--`, everything from which is the wrapped
# command and exempt (a reviewer role's own push or merge aside -- see reviewer_roles below), and
# whether that `--` sat inside quotes (`inner`: the wrapper is part of a quoted script, so its
# exemption ends at the script's own next separator -- see mark_soft_separators).
def detect_wrapper($w; $i; $n):
  if ($w[$i] | named("agent-identity.py")) and ($w[$i + 1] == "run") then
    (after_options($w; $i + 2)) as $role_i
    | if ($role_i < $n) and ($w[$role_i + 1] | IN("--", "--\u0002")) then
        {next: ($role_i + 2), role: $w[$role_i], inner: ($w[$role_i + 1] != "--")}
      else null end
  else null
  end;

# A reviewer identity never pushes or merges through this tool, whatever GitHub's own permission
# allows (contents:write, since a reviewer's APPROVE needs it -- see _REVIEWER_PERMISSIONS's own
# comment): a coder identity is the one that pushes and merges. Reviewer roles are named, not
# pattern-matched on "-reviewer": a role this list does not know (a typo, a role the brief never
# named) is not specially blocked here -- `tools/agent-identity.py` itself refuses to mint a token
# for a name outside its own ROLE_NAMES, which is the actual enforcement for an unknown role, not
# this check.
def reviewer_roles: ["claude-reviewer", "codex-reviewer"];
def is_push_like($reason): ($reason == "git push") or ($reason | startswith("tools/"));
def is_merge_like($reason):
  ($reason == "gh pr merge") or ($reason == "gh pr update-branch") or ($reason == "gh api merge-type");

# One pass over the word array: a hard separator resets the current command's exemption, and so
# does a soft one when the wrapper stood inside quotes (`inner`); any separator recomputes
# command position for the next word (`command_word`, from right after the separator); the wrapper
# pattern sets where its own command's exemption starts (and which role it names), and recomputes
# command position for the wrapped command the same way; anything else is checked against the
# three detectors, and a hit before the exemption (or with none active) is a finding -- as is a
# push- or merge-like hit inside a reviewer's own wrapper. A hit with no reason (a gh api/git
# command read as safe) is not a finding, but its own `next` still lets the pass skip everything
# it already scanned.
def findings($w):
  ($w | length) as $n
  | ([range(0; $n) | select($w[.] | test("(?i)mutation"))] | last // -1) as $lm
  | {i: 0, wrap_from: null, wrap_role: null, wrap_inner: false,
     cmd_word_index: (command_word($w; 0; $n)), out: [], reviewer_push: false}
  | until(.i >= $n;
      . as $state
      | ($w[$state.i]) as $x
      | (detect_wrapper($w; $state.i; $n)) as $wrap
      | ($state.i == $state.cmd_word_index) as $cmd_pos
      | if $x | is_sep then
          $state
          | (if ($x | is_hard_sep) or .wrap_inner
             then .wrap_from = null | .wrap_role = null | .wrap_inner = false else . end)
          | .cmd_word_index = (command_word($w; $state.i + 1; $n)) | .i += 1
        elif $wrap != null then
          $state | .wrap_from = $wrap.next | .wrap_role = $wrap.role | .wrap_inner = $wrap.inner
          | .cmd_word_index = (command_word($w; $wrap.next; $n)) | .i += 1
        else
          (detect_git($w; $state.i; $n) // detect_gh($w; $state.i; $n; $lm)
           // detect_tool($w; $state.i; $n; $cmd_pos)) as $hit
          | if $hit == null then $state | .i += 1
            elif $hit.reason == null then $state | .i = $hit.next
            else
              ($state
               | if (.wrap_from != null) and ($state.i >= .wrap_from) then
                   (if (is_push_like($hit.reason) or is_merge_like($hit.reason))
                       and ((reviewer_roles | index($state.wrap_role)) != null)
                    then .out += [$hit.reason] | .reviewer_push = true
                    else . end)
                 else .out += [$hit.reason] end
               | .i = $hit.next)
            end
        end)
  | {out, reviewer_push};

if (.tool_name | IN("Bash", "Monitor")) | not then empty else
  (.tool_input.command // "")
  | (if type == "string" then . elif type == "array" then map(tostring) | join(" ") else "" end)
  | (drop("\\\n") | swap(">&"; ">") | swap("<&"; "<") | swap("&>"; ">")) as $raw
  | ($raw | swap("${IFS}"; " ") | swap("$IFS"; " ") | swap("$\""; "\"")) as $bare
  | ($bare | words) as $w
  | (findings($w)) as $result
  | if ($result.out | length) == 0 then empty else $result end
end

JQ

command -v jq >/dev/null 2>&1 || exit 0
if ! result=$(jq -c "$check_program" 2>/dev/null); then
	flagged="(the guard's own jq program failed on this command, so it could not be checked)"
	reviewer_push=false
elif [ -z "$result" ]; then
	exit 0
else
	flagged=$(printf '%s' "$result" | jq -r '.out | join("; ")')
	reviewer_push=$(printf '%s' "$result" | jq -r '.reviewer_push')
fi

if [ "$reviewer_push" = "true" ]; then
	reason="This command ($flagged) runs as a reviewer identity (claude-reviewer or codex-reviewer), \
but reviewers never push or merge -- only a coder identity does. Wrap it in \
'uv run python tools/agent-identity.py run claude-coder -- <command>' (or codex-coder) instead. \
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
-- claude-coder or claude-reviewer in Claude Code, codex-coder or codex-reviewer in Codex -- never \
directly. Check first with 'uv run python tools/agent-identity.py status <role>'; if it reports \
the role not usable, stop and tell the player rather than running this directly. An admin action \
no bot identity can make (a repository ruleset, a GitHub App's own permissions) is the player's to \
do directly in GitHub's own settings, never something to wrap and retry. See committing and \
pr-review, and .claude/hooks/github-write-guard.sh for the current list of what counts as a write."
fi

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
exit 0
