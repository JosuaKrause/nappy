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
# A "write" is `git push`, `git commit` (its authorship is exactly what the wrapper sets), a
# GitHub-writing `gh pr`/`gh issue`/`gh release` verb, `gh api` with a non-GET method or
# -f/-F/--input fields, or one of the `tools/*.sh` scripts whose own body pushes or posts
# (`tools/release.sh`, `tools/prune-merged.sh`, `tools/land-prs.sh`, `tools/update-pr.sh` -- found
# with `rg` for `git push|git commit|gh pr |gh issue |gh release|gh api` over `tools/*.sh`; a
# script that only reads, such as `tools/agent-status.sh`'s `gh pr view`, is not on this list).
# Reads (`git status`, `git fetch`, `git log`, `gh pr view/list/diff/checks`, `gh issue
# list/view/status`, `gh release list/view/download`, a GET `gh api`) stay unguarded.
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

# `git <subcommand>`: push and commit are the only two writes named in the brief -- everything
# else (status, log, diff, fetch, merge, branch, ...) is a read or a local-only change.
def detect_git($w; $i; $n):
  if ($w[$i] | named("git")) | not then null
  else
    (after_options($w; $i + 1)) as $sub
    | if $sub >= $n then null
      elif $w[$sub] | IN("push", "commit") then {next: ($sub + 1), reason: ("git " + $w[$sub])}
      else null
      end
  end;

# `gh api`'s own writes: an explicit non-GET method, or any of -f/-F/--input (attached or not),
# which is what turns a call into a POST even with no --method at all.
def detect_gh_api($w; $start; $n):
  {i: $start, method: null, field: false}
  | until(.i >= $n or ($w[.i] | is_sep);
      $w[.i] as $x
      | if $x | IN("-X", "--method") then .method = ($w[.i + 1] // "") | .i += 2
        elif $x | startswith("--method=") then .method = ($x | ltrimstr("--method=")) | .i += 1
        elif $x | IN("-f", "-F", "--input", "--raw-field", "--field") then .field = true | .i += 1
        elif $x | test("^-[fF]") then .field = true | .i += 1
        else .i += 1
        end) as $r
  | if (($r.method != null) and (($r.method | ascii_downcase) != "get")) or $r.field
    then {next: $r.i, reason: "gh api"}
    else null
    end;

# `gh pr`/`gh issue`/`gh release` <verb>: the exact write list the brief gives for `pr`; for
# `issue` and `release`, everything but a named handful of reads (favouring deny over a verb this
# does not know about, the same fail-safe `after_options` uses for an option).
def detect_gh($w; $i; $n):
  if ($w[$i] | named("gh")) | not then null
  else
    (after_options($w; $i + 1)) as $noun_i
    | if $noun_i >= $n then null
      else
        ($w[$noun_i]) as $noun
        | ($noun_i + 1) as $verb_i
        | ($w[$verb_i]) as $verb
        | if $noun == "pr" then
            if ($verb != null) and ($verb | ascii_downcase | IN("create", "comment", "review", "merge", "edit", "close", "reopen", "ready"))
            then {next: ($verb_i + 1), reason: ("gh pr " + $verb)} else null end
          elif $noun == "issue" then
            if ($verb != null) and (($verb | ascii_downcase | IN("list", "view", "status")) | not)
            then {next: ($verb_i + 1), reason: ("gh issue " + $verb)} else null end
          elif $noun == "release" then
            if ($verb != null) and (($verb | ascii_downcase | IN("list", "view", "download")) | not)
            then {next: ($verb_i + 1), reason: ("gh release " + $verb)} else null end
          elif $noun == "api" then detect_gh_api($w; $verb_i; $n)
          else null
          end
      end
  end;

# A `tools/*.sh` entry point whose own body pushes or posts without saying so in the words this
# hook can see (see the header's own list and how it was found).
def write_tool_names: ["release.sh", "prune-merged.sh", "land-prs.sh", "update-pr.sh"];
def detect_tool($w; $i; $n):
  ($w[$i] | last_part) as $base
  | if write_tool_names | index($base) then {next: ($i + 1), reason: ("tools/" + $base)} else null end;

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
  | {i: 0, wrap_from: null, wrap_role: null, out: [], reviewer_push: false}
  | until(.i >= $n;
      . as $state
      | ($w[$state.i]) as $x
      | (detect_wrapper($w; $state.i; $n)) as $wrap
      | if $x | is_sep then $state | .wrap_from = null | .wrap_role = null | .i += 1
        elif $wrap != null then
          $state | .wrap_from = $wrap.next | .wrap_role = $wrap.role | .i += 1
        else
          (detect_git($w; $state.i; $n) // detect_gh($w; $state.i; $n) // detect_tool($w; $state.i; $n)) as $hit
          | if $hit == null then $state | .i += 1
            else
              ($state
               | if (.wrap_from != null) and ($state.i >= .wrap_from) then
                   (if (is_push_like($hit.reason)) and ((reviewer_roles | index($state.wrap_role)) != null)
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
