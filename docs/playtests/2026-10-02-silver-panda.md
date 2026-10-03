# Playtest silver-panda — The merged save PR review finds an unreadable xargs push

2026-10-02.

The player authorizes PR448 follow-ups in the session: "okay, you implement the 448
follow-ups on the side". They subsequently request fixing review issues and another review.
The new cloud delta review is posted by the player on PR448, attributed to an independent
Claude Code reviewer. It approves the existing correction but finds a new unreadable xargs
push. The player merges448 while this session is landing452, so the correction belongs in
a focused follow-up PR from main, not a change to the merged PR. No game runtime is affected.

The review is https://github.com/JosuaKrause/nappy/pull/448#issuecomment-5963732139.
Its complete text follows:

> ## Delta review of PR 448: 4fed6bcb → 3b328ba5
> Reviewer: Claude Code (not the author). Covers the corrections made after the earlier Claude
> cloud review. The rest of the PR was reviewed before.
>
> ### Blocking finding from the earlier review: fixed
> The write guard (.claude/hooks/github-write-guard.sh, which decides whether a git/gh command
> may go out under the player's GitHub account) let a substitution inside a quoted script
> through with no decision at all, e.g. `bash -c "git -C $(pwd) push origin v1.0.0"`, a tag
> push that deploys the site. The new check `soft_subcommand_opener` catches this: inside a
> quoted script, the substitution's opening bracket or backtick shows up as a placeholder
> character, and the check denies when that placeholder sits where the subcommand (or gh's
> noun/verb) belongs.
>
> I tested 50 command shapes against the hook at this head, in two settings: a cloud session
> with asking switched on, and a machine with identities. Each was sent as hook JSON; nothing
> ran. Results:
> - Denied in both settings: the four commands the earlier review named; their variants with a
>   second option after the substitution (`-c a=b`, a second `-C`); `--git-dir=$(…)/.git`;
>   `-C$(pwd)` with no space; `$( pwd )` with spaces; `$(printf %s .)`; `a$(pwd)`;
>   `$(pwd)/x`; nested `bash -c "bash -c '…'"`; `bash -lc`, `bash -ec`, `env bash -c`,
>   `timeout 5 bash -c`, `eval "…"`, `$'…'`, `<(…)` and `$((…))` forms; and gh with
>   `release create` or `api -X POST`.
> - Still allowed or asked as intended: `bash -c "git -C $(pwd) status"`, `git log --grep=push`,
>   `sh -c 'cd "$(git rev-parse --show-toplevel)" && git status'`, quoted `gh -R "$(cat r)" pr
>   view 3`. A plain branch push and the heredoc `git commit -m "$(cat <<'EOF' …)"` are asked
>   about in the cloud setting.
> - `bash -c "gh -R $(cat r) pr view 3"` (unquoted, a read) is denied. The record lists this as
>   an accepted false denial for the bare form, so it is consistent.
>
> ### The optional and nit findings: fixed
> - Inline `push.default=matching` (which makes a push send every matching branch) is now
>   denied in every spelling, even next to an explicit refspec. Tests cover `-cpush…`, mixed
>   case, quoted and overridden forms.
> - The `> v.log` false denial is now listed in the frosty-pelican record.
> - TELEMETRY.md, the comment in main.gd's `_restart_run()` and the rosy-chipmunk record now
>   say a late web deletion answer may land in the next run's log.
> - The comment on main.gd's `_carry_the_save_symbol_over()` now says a symbol once carried to
>   the tree root stays there and is adopted again.
> - The rosy-chipmunk record says the closure compiler defaults to off in the pinned source,
>   links the symbol picture, and gives its exact rerun command.
> - The plush-ibis playtest records the supplied review in full.
>
> ### What I ran (at 3b328ba5, in a separate scratch checkout)
> - tools/test_rules_hooks.sh: 2108 checks, 0 failures.
> - Codex adapter tests (tools/test_codex_hooks.py, run with unittest): 57 tests pass.
> - CI on this head: classify, gates, game, test and all 8 shards are green.
>
> ### New findings
>
> 1. [low · non-blocking] A refspec supplied by xargs is asked about rather than denied.
>    With asking switched on in a cloud session:
>      echo v1 | xargs -I{} git push origin {}     → ask   (pushes tag v1, which deploys)
>      xargs git push origin < tags.txt            → ask
>    On main both are denied, because main denies every unwrapped push. The guard reads `{}` as
>    a branch name and never sees what xargs feeds in. The record promises a `v*` tag push is
>    "never asked about, only denied", and the PR's own rule denies a push "the guard cannot
>    read to its end". The player still sees the command in the prompt, and an agent is
>    unlikely to push through xargs, which is why this is not blocking.
>    Fix: when a `git push` runs under the xargs wrapper, treat it as unreadable and deny it.
>    Or list it under "Deliberate limits" in docs/decisions/2026-10-02-frosty-pelican.md.
>
> 2. [nit · no change needed] `bash -c "git -C $[1] push origin v1.0.0"` gets no decision at
>    all in either setting (also on main). `$[…]` is bash's old arithmetic syntax and only ever
>    produces a number, so this needs a directory named by a number. The guard's header puts
>    deliberately evasive shapes outside its bar ("a guardrail, not a security boundary"), so
>    this is noted, not asked for.
>
> ### Not checked
> - The save runtime didn't change in this delta (comments and docs only); earlier reviews
>   covered it.
> - A release web export and a real iPhone remain unverified, as the PR itself says.
>
> Verdict: ready — 3b328ba57eb38fb3e96938d9ab3da8aeb72c429f
