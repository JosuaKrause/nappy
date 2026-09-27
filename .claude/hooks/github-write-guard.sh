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
# A "write" is `git push`; a commit-making git verb (`commit` -- its authorship is exactly what
# the wrapper sets -- `cherry-pick`, `revert`, `am` always, `merge`/`rebase` unless they carry
# `--abort`/`--no-commit`/`--ff-only`, which make no commit of their own); any `gh` noun's verb
# that is not on one short, shared read list (`view`, `list`, `status`, `diff`, `checks`,
# `checkout`, `search`) -- every noun, not only `pr`/`issue`/`release`, so `gh workflow run`, `gh
# run rerun`, `gh repo edit`, `gh label create`, `gh secret set`, `gh variable set`, `gh cache
# delete` and `gh gist create` all write and are caught the same fail-safe way an unknown verb is;
# `gh api` with a non-GET method or `-f`/`-F`/`--input`/`--raw-field`/`--field`, attached or not;
# or one of the `tools/*.sh` scripts whose own body pushes or posts (`tools/release.sh`,
# `tools/prune-merged.sh`, `tools/land-prs.sh`, `tools/update-pr.sh` -- found with `rg` for `git
# push|git commit|gh pr |gh issue |gh release|gh api` over `tools/*.sh`; a script that only reads,
# such as `tools/agent-status.sh`'s `gh pr view`, is not on this list), and only when its name is
# in command position (the first word of a command, or right after `bash`/`sh`/`env`/`timeout`/
# `xargs`/`nice`/`nohup`/`sudo`/`command`/`watch`) -- reading the file (`cat`, `sed`, `git log
# --`/`diff --`/`show`, `rg`) never denies -- and, for `release.sh`, only with its own `push`
# argument, for `land-prs.sh`/`update-pr.sh`, only without their own `--dry-run`.
# Reads (`git status`, `git fetch`, `git log`, `gh pr view/list/diff/checks/checkout`, `gh
# issue/release list/view`, `gh browse`, a GET `gh api`) stay unguarded.
#
# **A reviewer identity (`claude-reviewer`, `codex-reviewer`) never pushes, wrapped or not.** Its
# GitHub App has `contents: write` (a reviewer's own APPROVE needs it to satisfy a required-approval
# ruleset -- see `_REVIEWER_PERMISSIONS`'s own comment in `tools/agent-identity.py`), so GitHub
# itself would let it push; this tool still refuses, on the theory that reviewing and coding stay
# two identities even where GitHub's permission model would allow one to do both. So `git push` and
# the pushing `tools/*.sh` scripts are denied even inside `run claude-reviewer --`/`run
# codex-reviewer --`, with a message naming the coder identity to use instead.
#
# The escape is `tools/agent-identity.py run <role> -- <command>`, with or without a `uv run
# python` (or bare `python`/`python3`) in front, and with or without `run`'s own `--repo
# OWNER/REPO` between `run` and `<role>`: everything at and after that literal `--`, up to the
# next real command separator, is exempt. Nothing before the `--`, or in a different
# `;`/`&`/`|`/newline-separated command on the same line, is.
#
# **This prefers a false deny to a false allow**, the same call `git-grep-guard.sh` makes and for
# the same reason: telling a mention from a real invocation is a parser that keeps having holes,
# and the failure mode of an over-eager deny (rerun the command through the wrapper) is far
# cheaper than the failure mode of a miss (a post lands under the player's own account again,
# which is the whole thing this rule exists to stop). So this reads the command's raw text, quotes
# and backslashes stripped before it is split into words, and a mention (a write's name inside an
# echo, a commit message, a code comment) denies exactly like a real invocation would. The one
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

# Quotes and backslashes are dropped before the split (mentions read like invocations, on
# purpose -- see the header). `,`, `[` and `]` join whitespace as word breaks (a Python argument
# list, `subprocess.run(["git", "push"])`, must not hide the words inside its brackets); `;`, `&`,
# `|`, `(`, `)`, a backtick and a newline are words of their own, each ending a chain of commands.
def words:
  drop("\\") | drop("\"") | drop("'")
  | swap("\t"; " ") | swap(","; " ") | swap("["; " ") | swap("]"; " ")
  | swap(";"; " ; ") | swap("&"; " & ") | swap("|"; " | ")
  | swap("("; " ( ") | swap(")"; " ) ") | swap("`"; " ` ") | swap("\n"; " \n ")
  | split(" ") | map(select(length > 0));

def is_sep: IN(";", "&", "|", "(", ")", "`", "\n");

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

# `git <subcommand>`: push, and every subcommand that can create a commit under the invoking
# user's own name -- commit, cherry-pick, revert and am always; merge and rebase only when they
# are not the abort/no-op shape (`git merge --abort`/`--no-commit`/`--ff-only` and `git rebase
# --abort` make no commit of their own; merging-main's own `--no-ff --no-commit` + a later `git
# commit` is still covered, by that later `git commit`). Everything else (status, log, diff,
# fetch, branch, ...) is a read or a local-only change.
def commit_making_verbs: ["commit", "cherry-pick", "revert", "am"];
def segment_has_any($w; $start; $n; $flags):
  {j: $start, found: false}
  | until(.j >= $n or ($w[.j] | is_sep) or .found;
      . as $s | .found = (($flags | index($w[$s.j])) != null) | .j += 1)
  | .found;
def detect_git($w; $i; $n):
  if ($w[$i] | named("git")) | not then null
  else
    (after_options($w; $i + 1)) as $sub
    | if $sub >= $n then null
      else
        ($w[$sub]) as $subcmd
        | if $subcmd == "push" then {next: ($sub + 1), reason: "git push"}
          elif commit_making_verbs | index($subcmd) then {next: ($sub + 1), reason: ("git " + $subcmd)}
          elif $subcmd == "merge" then
            if segment_has_any($w; $sub + 1; $n; ["--abort", "--no-commit", "--ff-only"])
            then null else {next: ($sub + 1), reason: "git merge"} end
          elif $subcmd == "rebase" then
            if segment_has_any($w; $sub + 1; $n; ["--abort"]) then null else {next: ($sub + 1), reason: "git rebase"} end
          else null
          end
      end
  end;

# `gh api`'s own writes: an explicit non-GET method (`-X`/`--method`, attached or not, any case:
# `-XPOST`, `-X=POST`, `--method=post`), or any of -f/-F/--input/--raw-field/--field (attached or
# not: `-fk=v`, `--field=k=v`) -- which is what turns a call into a POST even with no `--method` at
# all. The scan stops at the next `git`/`gh` word too, not only at a separator, so a run of many
# `gh api ...` calls glued together with no separator between them (measured: 800 repeats took
# 9.4s of the hook's 10s timeout before this bound existed) stays linear rather than quadratic --
# the same reason `git-grep-guard.sh` bounds its own scan.
def detect_gh_api($w; $start; $n):
  {i: $start, method: null, field: false}
  | until(.i >= $n or ($w[.i] | is_sep) or ($w[.i] | named("gh")) or ($w[.i] | named("git"));
      $w[.i] as $x
      | if $x | IN("-X", "--method") then .method = ($w[.i + 1] // "") | .i += 2
        elif $x | startswith("--method=") then .method = ($x | ltrimstr("--method=")) | .i += 1
        elif $x | test("^(?i)-X=?.+") then .method = ($x | sub("^(?i)-X=?"; "")) | .i += 1
        elif $x | IN("-f", "-F", "--input", "--raw-field", "--field") then .field = true | .i += 1
        elif $x | test("^--(field|raw-field|input)=") then .field = true | .i += 1
        elif $x | test("^-[fF].+") then .field = true | .i += 1
        else .i += 1
        end) as $r
  | if (($r.method != null) and (($r.method | ascii_downcase) != "get")) or $r.field
    then {next: $r.i, reason: "gh api"}
    else null
    end;

# Every `gh` noun writes unless its verb is on one short, shared list of reads: `view`, `list`,
# `status`, `diff`, `checks`, `checkout` (`gh pr`'s own local-only checkout) and `search`. This is
# the same fail-safe `gh issue`/`gh release` already used, generalised to the whole of `gh` --
# `workflow run`, `run rerun`/`cancel`/`delete`, `repo edit`, `label create`, `secret set`,
# `variable set`, `cache delete`, `gist create`, ... all write and are caught the same way a verb
# this list has never heard of is: denied, not read as a pass. `gh browse` opens a local browser
# with no GitHub write of its own and is never denied; `gh api` is `detect_gh_api`'s.
def generic_reads: ["view", "list", "status", "diff", "checks", "checkout", "search"];
def detect_gh($w; $i; $n):
  if ($w[$i] | named("gh")) | not then null
  else
    (after_options($w; $i + 1)) as $noun_i
    | if $noun_i >= $n then null
      else
        ($w[$noun_i]) as $noun
        | if $noun == "browse" then null
          elif $noun == "api" then detect_gh_api($w; (after_options($w; $noun_i + 1)); $n)
          else
            (after_options($w; $noun_i + 1)) as $verb_i
            | ($w[$verb_i]) as $verb
            | if $verb == null then null
              elif $verb | ascii_downcase | IN(generic_reads[]) then null
              else {next: ($verb_i + 1), reason: ("gh " + $noun + " " + $verb)}
              end
          end
      end
  end;

# Words that hand a command to something else to run, carrying "command position" forward to the
# word right after them: `bash`/`sh` run a script file, `env`/`timeout`/`xargs`/`nice`/`nohup`/
# `sudo`/`command`/`watch` run the word after their own options.
def wrapper_words: ["bash", "sh", "env", "timeout", "xargs", "nice", "nohup", "sudo", "command", "watch"];

# A `tools/*.sh` entry point whose own body pushes or posts without saying so in the words this
# hook can see (see the header's own list and how it was found) -- guarded only in command
# position (the first word of a command, or right after one of `wrapper_words`), never where its
# name is merely a read's argument (`cat tools/release.sh`, `git log -- tools/land-prs.sh`, `git
# show HEAD:tools/release.sh`, `rg ... tools/update-pr.sh`). `release.sh` only tags and pushes when
# its own second positional argument is literally `push` (see its usage); `land-prs.sh` and
# `update-pr.sh` both skip every GitHub write under `--dry-run`; `prune-merged.sh` has no dry-run
# shape and is a write whenever it runs at all.
def write_tool_names: ["release.sh", "prune-merged.sh", "land-prs.sh", "update-pr.sh"];
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
# command and exempt (a reviewer role's own push aside -- see reviewer_may_push below).
def detect_wrapper($w; $i; $n):
  if ($w[$i] | named("agent-identity.py")) and ($w[$i + 1] == "run") then
    (after_options($w; $i + 2)) as $role_i
    | if ($role_i < $n) and ($w[$role_i + 1] == "--") then {next: ($role_i + 2), role: $w[$role_i]} else null end
  else null
  end;

# A reviewer identity never pushes through this tool, whatever GitHub's own permission allows
# (contents:write, since a reviewer's APPROVE needs it -- see _REVIEWER_PERMISSIONS's own
# comment): a coder identity is the one that pushes. Reviewer roles are named, not pattern-matched
# on "-reviewer", so a role this list does not know fails safe (denied like an unwrapped write).
def reviewer_roles: ["claude-reviewer", "codex-reviewer"];
def is_push_like($reason): ($reason == "git push") or ($reason | startswith("tools/"));

# One pass over the word array: a separator resets the current command's exemption; the wrapper
# pattern sets where its own command's exemption starts (and which role it names); anything else
# is checked against the three detectors, and a hit before the exemption (or with none active) is
# a finding -- as is a push-like hit inside a reviewer's own wrapper.
def findings($w):
  ($w | length) as $n
  | {i: 0, wrap_from: null, wrap_role: null, cmd_pos: true, out: [], reviewer_push: false}
  | until(.i >= $n;
      . as $state
      | ($w[$state.i]) as $x
      | (detect_wrapper($w; $state.i; $n)) as $wrap
      | (if $x | is_sep then true
         elif ($state.i + 1) == $state.wrap_from then true
         elif $state.cmd_pos and ((wrapper_words | index($x | last_part)) != null) then true
         else false end) as $next_cmd_pos
      | if $x | is_sep then $state | .wrap_from = null | .wrap_role = null | .cmd_pos = $next_cmd_pos | .i += 1
        elif $wrap != null then
          $state | .wrap_from = $wrap.next | .wrap_role = $wrap.role | .cmd_pos = $next_cmd_pos | .i += 1
        else
          (detect_git($w; $state.i; $n) // detect_gh($w; $state.i; $n)
           // detect_tool($w; $state.i; $n; $state.cmd_pos)) as $hit
          | if $hit == null then $state | .cmd_pos = $next_cmd_pos | .i += 1
            else
              ($state
               | if (.wrap_from != null) and ($state.i >= .wrap_from) then
                   (if (is_push_like($hit.reason)) and ((reviewer_roles | index($state.wrap_role)) != null)
                    then .out += [$hit.reason] | .reviewer_push = true
                    else . end)
                 else .out += [$hit.reason] end
               | .cmd_pos = $next_cmd_pos
               | .i = $hit.next)
            end
        end)
  | {out, reviewer_push};

if (.tool_name | IN("Bash", "Monitor")) | not then empty else
  (.tool_input.command // "")
  | (if type == "string" then . elif type == "array" then map(tostring) | join(" ") else "" end)
  | (drop("\\\n") | swap(">&"; ">") | swap("<&"; "<") | swap("&>"; ">")) as $raw
  | ($raw | swap("${IFS}"; " ") | swap("$IFS"; " ") | swap("$'"; "'") | swap("$\""; "\"")) as $bare
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
but reviewers never push -- only a coder identity does. Wrap it in \
'uv run python tools/agent-identity.py run claude-coder -- <command>' (or codex-coder) instead. \
See committing and pr-review."
else
	reason="This command writes to GitHub ($flagged) outside any agent identity. Every git push, git \
commit, GitHub-writing gh pr/issue/release/api call, and pushing/posting tools/ script runs \
through 'uv run python tools/agent-identity.py run <role> -- <command>' instead -- claude-coder or \
claude-reviewer in Claude Code, codex-coder or codex-reviewer in Codex -- never directly. Check \
first with 'uv run python tools/agent-identity.py status <role>'; if it reports the role not \
usable, stop and tell the player rather than running this directly. See committing and pr-review, \
and .claude/hooks/github-write-guard.sh for what counts as a write."
fi

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
exit 0
