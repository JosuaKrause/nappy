# frosty-pelican — Where no identity can work, the write guard asks the player about an ordinary write · 2026-10-02 · not from an entry

**What it overturns.** [tall-egret, each agent posts on GitHub as an app of its own](2026-09-27-tall-egret.md)
records the player's choice, asked what an agent does when its identity is unusable, of "Stop
and tell me": `.claude/hooks/github-write-guard.sh` denied every unwrapped GitHub write, and a
session whose `tools/agent-identity.py status` said no role worked stopped there. That choice is
overturned, once the player switches the asking on, in exactly the two places where no identity
can work at all: a Claude Code cloud session (`CLAUDE_CODE_REMOTE=true`) and a machine with no
identity directory. Everywhere else it stands, and so does it for Codex. In a cloud session no role
ever works (the session's proxy refuses the API paths the manifest flow needs, and there is no
browser for its confirm page), so the guard made even a local `git commit` impossible, and a
cloud session could not commit or push its own work at all; a machine with no identity directory
is in the same place until identities are set up on it.

**What the player asked for.** In a cloud session that had built the rosy-chipmunk save fix and
could not commit it, the assistant offered two ways to let one write through safely: (A) the
guard answers "ask" instead of "deny", so Claude Code shows the player a permission prompt for
that exact command, or (B) the player types a grant line that a prompt hook turns into a
short-lived grant file. It recommended (A), since the player alone can answer a permission
prompt while a grant file is one the agent could write itself. The player chose:

> "Let's do A and make the codex version always refuse"

**What is built.** Where no identity can work — `CLAUDE_CODE_REMOTE=true`, or no identity
directory at `$NAPPY_AGENTS_DIR` or `~/.config/nappy-agents` — the guard answers `ask` for a
command whose every write is on `askable_reasons`: `git commit`, an ordinary `git push` of a
branch, the local history verbs (`merge`, `rebase`, `pull`, `cherry-pick`, `revert`, `am`), and
`gh pr create|comment|edit|ready`. Its reason tells the player the command would go out under
their own account and that the next one is asked about again. Everything else stays denied
wherever the session runs, because a prompt is too easy to click through, and on the mobile app it
shows only the command:

- a push that rewrites or deletes on the remote, its own reason `git push --force`: `-f` or a
  short-flag cluster holding `f` or `d`, `--force`, `--force-with-lease`, `--force-if-includes`,
  `--delete`, `--mirror`, `--prune`, a `+` or `:` refspec, a git option before `push` naming
  `mirror` (`git -c remote.origin.mirror=true push`), and a push refspec set by a git option
  before `push` that starts with `+` or `:` (`git -c remote.origin.push=:main push origin`
  deletes `main`). The keys read as push refspecs are `remote.<name>.push` and
  `branch.<name>.merge`, where a push goes under `push.default=upstream`;
- a push of a tag or of every branch, its own reason `git push of a tag or every branch`, since
  `.github/workflows/deploy.yml` publishes the site on every pushed `v*` tag: `--tags`,
  `--follow-tags`, `--all`, any refspec holding a `*` (`'refs/*:refs/*'` pushes every tag,
  `'refs/heads/*:refs/heads/*'` is `--all` spelled out, and pushing a pattern is never an ordinary
  push of one branch), a refspec naming `refs/tags/` or `tags/`, `git push <remote> tag <name>`, a
  ref whose name starts with `v` on either side of a refspec's `:` (`vnext`, `HEAD:v1.2.0`), and a
  git option before `push` naming `followTags` or `refs/tags/` or holding a `*` (`git -c
  push.followTags=true push`), and a push refspec set by a git option before `push` that the same
  tests read as a tag (`git -c remote.origin.push=HEAD:v1.0.0 push origin`). `git tag` itself
  stays unguarded, since it changes only the local repository and every way a tag then reaches
  GitHub is a push the guard reads;
- a push with a shell expansion among its words, its own reason `git push with a shell
  expansion`: any word after `push` holding a `$` (`git push origin "$TAG"`, `"$(git describe
  --tags)"`, `${B}`), a backtick substitution (`` git push origin `echo v1.0.0` ``), and, before
  `push`, a push refspec setting whose value holds a `$`, one read from the environment
  (`--config-env`), or a `-c` whose key holds a `$` (`git -c "$CFG" push`). The guard cannot know
  what such a word becomes, and `"$TAG"` can be a `v*` tag. The remote and an option's own value
  count too (`git push "$REMOTE" x`, `-o "$X"`): by the time the words are read the quotes are
  gone, so a quoted `"$X"` cannot be told from an unquoted `$X` that the shell splits into words
  landing in refspec position;
- a push the guard cannot read to its end, its own reason `git push that cannot be read`: one
  whose own quoted or escaped word holds a separator (`git push -o 'a;b' origin v1`, `git push
  origin 'x;y' v1`, `git push origin \; v1`), since the scan stops at a separator and would leave
  every word after it unread, and a push refspec setting that goes on past one plain word (`git
  -c 'remote.origin.push=a b' push`). A separator belongs to the push when the push stands outside
  quotes, or when it sits deeper in quotes than the push's own words (`bash -c "git push -o 'a;b'
  origin v1"`). One at the push's own level inside a quoted script is the script's (`bash -c "git
  push origin x; git status"`), and one in another command is that command's (`git commit -m "a;
  b" && git push origin x`), so both of those are still asked about;
- a `git` whose options hold a command substitution written outside quotes, or whose subcommand
  is itself an expansion, its own reason `git with a shell expansion before its subcommand`
  (`git -C $(pwd) push origin main`, `git $(echo push) origin v1`), when the name of a
  commit-making or pushing subcommand appears anywhere after it in the command. The
  substitution's words end the option run or are taken for the subcommand, so the push behind
  them was never read at all: unwrapped, this shape was allowed outright, on a machine with
  identities too, and it is now denied there as well. `gh` the same way (`gh -R $(cat r) pr merge 3`), always.
  Written inside quotes (`git -C "$(pwd)" push origin x`) the substitution is one argument, and
  the push is read and asked about as usual;
- each of those long options in any spelling git acts on, since git takes any unambiguous prefix
  of a long option (`--del`, `--mir`, `--pru`, `--ta`, `--fol`, `--al`), and in the shorter,
  ambiguous ones too (`--fo`, `--d`, `--p`, `--t`, `--a`), where reading a prefix git refuses as
  the stricter push is the safe direction;
- a bare `gh issue` write. The player said an agent's issue writes go through a script, not a
  direct command (bouncy-heron statement 14: "if it goes through a script it's safe we just need
  to get it working once -- an agent shouldn't use gh issue directly"), so the prompt does not
  open a direct route that the open queue item under `docs/todo/2026-09-27-leafy-finch/` is
  meant to close;
- a pull request's merge, a release, every other `gh` write, any `gh api` write, a pushing
  `tools/` script, a reviewer's push, a command too long to read and one the guard cannot parse.

**Deliberate limits.** Any ref whose name starts with `v` reads as a tag, because the deploy fires
on any `v*` tag, whatever follows the `v`, and a bare name does not say whether it is a tag or a
branch. So a branch whose name starts with `v`, pushed by that bare name, is denied rather than
asked about; that cost is accepted because this repository's branches are named `claude/...`,
`feature/...` and `work/...`, and a push naming an explicit `refs/heads/` destination
(`HEAD:refs/heads/v1`) is a branch push and is still asked about. The name test reads only the
refspecs, not the remote or an option's own value, so `git push vendor HEAD` is asked about; the
remote is the first word after `push` that is neither an option nor the value of one of the few
options that take the next word (`-o`, `--repo`, `--receive-pack`, `--exec`,
`--recurse-submodules`, spelled in full). The reading only ever errs towards taking an earlier word
for the remote, which leaves every real refspec read: a prefix of one of those options (`git push
--rep vendor vnext`) reads as taking no value, so `vendor` is taken for the remote and `vnext` is
denied, where git would push to a remote named `vnext`. A `push.followTags`, mirror or push
refspec setting made earlier by a separate `git config` command, or passed through the
environment (`GIT_CONFIG_COUNT` with `GIT_CONFIG_KEY_0`/`GIT_CONFIG_VALUE_0`,
`GIT_CONFIG_PARAMETERS`), is not visible to the guard, so a plain push after it is asked about.

The expansion and unreadable rules deny some ordinary pushes, the safe direction: any push whose
words hold a `$` for any reason (`git push origin "$(git branch --show-current)"`, an output
redirect to `"$LOG"`, a trailing comment that mentions `$5`), a push inside backticks (it ends at
the closing backtick), and a quoted separator in a push's own option value (`-o "ci(skip)"`). A
read is denied too where an unquoted substitution sits in `gh`'s options (`gh -R $(cat r) pr view
3`), or in `git`'s when a write subcommand's name appears later in the command (`git -C $(pwd)
status && git push origin x` is denied for the `status`). The rule that tells a push's own quoted
separator from a quoted script's cannot see a separator escaped with a backslash inside that
script (`bash -c "git push origin \; v1"`), which sits at the script's own level and is read as
the script's: an accepted gap, since only a deliberately built command has one.

On a machine with identities set up nothing changes: an unwrapped write is denied and the agent
wraps it. `tools/codex-hooks.py` turns any decision a guard names into a deny — an ask, and an
explicit allow too, which neither guard gives — so Codex never asks and keeps "stop and tell the
player"; without that, an `ask` passed through the adapter would have read as an allow. Codex's
deny reason is a refusal of its own that names what the guard flagged, not the prompt text meant
for the player.

**The player can switch it off.** After it was built the player asked:

> "Make it so it can be easily turned off and refuse again later. So I can turn it on/off without
> approval hacks"

Asked which way it should default, the player chose:

> "Yes default to refusing"

So the asking is off unless `NAPPY_ASK_FOR_PLAYER_WRITES=1` is in the environment a session
starts with; unset, or any other value, and every unwrapped write is denied, as on a machine with
identities. The switch is an environment variable rather than a file in the repository because a command an agent
runs cannot change the environment its hooks are started in, while a file it can write: the
player sets it in a cloud environment's own variables (its settings, then Edit, picked up by a new
session) or in the shell that launches Claude Code. The ask's own prompt text names the variable,
so the player meets the off switch the first time the guard asks.

**Rejected.** (B), the typed grant line: a grant file is something the agent could create itself,
which the guard could only discourage, and whether a message the player sends while the agent is
mid-turn reaches a prompt hook is not documented. Pushing through the GitHub connector instead of
git was used once for the rosy-chipmunk branch, on the player's say-so, and is not a route: the
connector takes whole files, so a two-line change to a 160 KB file means retyping all of it.

**Verified.** `tools/test_rules_hooks.sh` (the guard's cases now run pinned to a machine with
identities, plus each ask and deny shape above under a cloud session and under no identity
directory, with the switch on and with it off) and `tools/pycheck.sh` (with a Codex test that a
cloud session's or an unconfigured machine's ask reaches Codex as a deny whose reason is a
refusal, and one that an explicit allow does too) pass; `tools/codex-hooks.py` still runs under the host's
Python 3.11. A Claude Code cloud session shows the prompt: in a cloud session started with
`NAPPY_ASK_FOR_PLAYER_WRITES=1`, running in auto mode, a plain `git commit` and the `git push` after
it each brought up a permission prompt the player saw and approved. In the Claude desktop app the
prompt shows the guard's own text, that the command "would go out under the player's own GitHub
account"; in the mobile app it shows only the command, so a player approving from a phone sees
the command and not the reason.
