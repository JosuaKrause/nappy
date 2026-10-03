# Playtest grassy-yak — Review corrections for unreadable input-driven pushes

2026-10-03.

The player asks in conversation:

> in parallel address comments on 453 455 456

The following reviews are posted by the player. Reviewer analysis is quoted as review,
not as firsthand gameplay feedback. Their second comment explicitly requests GNU parallel.

Source: [PR #453 review](https://github.com/JosuaKrause/nappy/pull/453#issuecomment-5964803406).

> ## Review of PR #453 — Deny unreadable pushes supplied through xargs
>
> **Verdict: not ready** at head 84b2aeb75e091fb6747517fd35c346ee4ad37d56. 0 blocking, 2 should-fix, 2 nits.
>
> The fix is correct and well tested; the remaining items are small.
>
> ### Should-fix
>
> **1. GNU `parallel` passes input-supplied refspecs to the push the same way, and is still asked about**
> `.claude/hooks/github-write-guard.sh:466`, `:1024` (the `named("xargs")` checks)
>
> Run at the head in a cloud session with asking on (`CLAUDE_CODE_REMOTE=true NAPPY_ASK_FOR_PLAYER_WRITES=1`), hook JSON only, no push executed:
>
> | Command | Decision | Note |
> |---|---|---|
> | `echo v1 \| parallel git push origin` | ask | pushes tag v1, which deploys the site |
> | `parallel git push origin {} < t` | ask | |
> | `ls \| parallel -j1 git push origin {}` | ask | |
>
> This is the shape the source review flagged:
> - a `v*` tag push, which the frosty-pelican record says is "never asked about, only denied";
> - a push "the guard cannot read to its end".
>
> `find … -exec git push origin {} \;` is already denied, but only by accident: `\;` reads as an unreadable separator and `{} +` as a force refspec.
>
> Fix: in both places, change `named("xargs")` to `named("xargs") or named("parallel")`, and add one test that it is never asked. Or, if you treat `parallel` as beyond the source's words, name it under "Limits" in `docs/decisions/2026-10-02-striped-lark.md` so the gap is recorded rather than silent.
>
> **2. The player's request for this work is paraphrased, not quoted**
> `docs/playtests/2026-10-02-silver-panda.md:5-6`
>
> - "They subsequently request fixing review issues and another review" is the only record of what the player asked for.
> - The one quote, "okay, you implement the 448 follow-ups on the side", is the earlier authorization, not the request.
> - Playtest files are primary sources: the player's own words on a date.
>
> Fix: quote the player's actual message, or say plainly that no text of it exists.
>
> The reviewer text itself is verbatim: it diffs clean against issue comment 5963732139.
>
> ### Nits
>
> **3. Missing spaces**
> `docs/playtests/2026-10-02-silver-panda.md:9`
>
> "The player merges448 while this session is landing452" should read "merges 448 … landing 452". Fix it before merge, since playtests are never rewritten afterwards.
>
> **4. The PR description claims a queue removal that never reached main**
> PR description: "This completes striped-lark … Its queue item is removed."
>
> - striped-lark was never queued on main. 6ce0d5d filed `docs/todo/2026-10-02-striped-lark/` and 84b2aeb deleted it, both on this branch.
> - The net diff touches nothing under `docs/todo/`.
> - The squash commit message is taken from the PR description, so main's history would claim a removal that didn't happen there.
>
> Fix: say the item was filed and closed within this PR.
>
> ### Checked and clean
>
> **Fits the source review**
> - Implements its first suggested fix (treat a git push under xargs as unreadable and deny it), and covers both named cases.
> - The extra conservative denials are marked as open to overturn: ordinary xargs branch pushes, literal mentions of xargs, and uncertain quoted separators.
> - The `$[…]` observation, which asked for no change, is correctly left out.
>
> **Keeps recorded decisions**
> - frosty-pelican's contract holds: refuse a publishing or unreadable push; ask only about a branch push, a commit or a PR write; the switch is off by default.
> - tall-egret's identity rule holds.
> - The committing skill's wording and the hook's own comments still read true.
>
> **About 100 hook-JSON probes, base (6006fa6) against head**
> - About 60 xargs variants change from ask to deny ("git push that cannot be read"):
>   - xargs options: `-0`, `-a`/`--arg-file`, `-d`, `-I`/`-i`/`--replace`, `-n`/`-L`/`-P`, `-r`, `-t`, `-p`, `-s`, `-E`, `--`;
>   - wrappers: `command`/`env`/`/usr/bin`/`sudo`/`nohup`/`time` before xargs, and `nice`/`sudo`/`timeout`/`env` after it;
>   - git options: `git -C`/`-c`;
>   - command structure: pipes, subshells, `{ }`, `if`/`for`, heredoc input;
>   - quoted scripts containing `;`, `&&`, `||`, `|`, `&`, a newline, `if/then` or `( )`;
>   - nested `sh -c`, `bash -lc`, `bash -c --`, and `python3 -c os.system`.
> - Reads stay allowed: `xargs git status`, `xargs grep -l push`, `git log | xargs echo`.
> - A later, separate push is still asked about:
>   - after `;`, `&&`, `||`, `|` and `&`, inside and outside quoted scripts;
>   - in the heredoc commit idiom with a message that mentions xargs;
>   - for a branch named `…xargs…`, after a `# xargs` comment, and after `FOO=xargs`.
>
> **Expected false denials (all documented choices)**
> - `xargs rg 'git push' < files` is now denied (mentions count).
> - `bash -c "cd $(pwd); xargs git status; git push origin x"` is denied (uncertain quote).
> - A deliberately misquoted `sh -c` shape is still asked about, which falls within the parser gaps the guard already accepts.
>
> **Tests and CI**
> - `tools/test_rules_hooks.sh` at head: 2284 checks, 0 failures.
> - The head's test file against the base guard: 25 failures, all of them new xargs cases, so the tests do fail before the fix.
> - The ask and allow controls would catch an over-broad rule.
> - `tools/lint.sh` passes, CI is all green on 84b2aeb, and the branch merges cleanly into current origin/main.
>
> **Performance**
> A 63 KB command with 3000 xargs words takes 2.95s at head against 2.93s at base, so no regression.
>
> **Codex adapter**
> - `tools/codex-hooks.py` passes the command through unchanged and turns any named decision into a deny.
> - No tool name, payload field or hook event changed, so it needs no update.
> - `python3 -m unittest tools/test_codex_hooks.py`: 57 tests OK.
> - A live adapter call with an xargs push returns deny.
>
> **Identities**
> - A coder-wrapped xargs push, and xargs invoking the coder wrapper, are allowed.
> - A reviewer-wrapped xargs push is denied.
> - With the switch off, every new case is denied.
> - The author, nappy-codex-coder[bot], is the right identity for a Codex PR that changes code.
>
> **Record**
> - The names striped-lark and silver-panda are unique on main.
> - The record has its source, what was built, the choices open to overturn, what was kept, the verification and the limits.
> - It contains no quest log.

Source: [PR #453 review](https://github.com/JosuaKrause/nappy/pull/453#issuecomment-5964962169).

> ## PR #453 — review update (head 84b2aeb)
>
> **Finding 1 (`parallel`): the player asks for it in this PR.** The player: "let's do parallel the fix is reasonably sized".
>
> - Treat `parallel` like `xargs` in both places:
>   - `github-write-guard.sh:466`, in `xargs_context`;
>   - `github-write-guard.sh:1024`, the `any($w[]; named("xargs"))` check.
> - Tests, never asked about:
>   - `echo v1 | parallel git push origin`
>   - `parallel git push origin {} < t`
>   - `ls | parallel -j1 git push origin {}`
> - Allow control: `parallel git status`.
> - Name `parallel` next to `xargs` in:
>   - the header comment ("A push under xargs cannot be read to its end…");
>   - the striped-lark record, with the player's words above as its source.
>
> Findings 2-4 are unchanged.
>
> **Verdict: not ready** at 84b2aeb.
