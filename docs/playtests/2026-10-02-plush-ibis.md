# Playtest plush-ibis — Cloud review follow-ups for PR 448

2026-10-02.

The player has authorized implementing PR 448's follow-ups and taking over its description.
An independent Codex review approved its existing head after the description's image was
fixed. The player then supplied this cloud review, which changes the verdict and supplies
the next corrections. The cloud reviewer cannot post to GitHub. These findings belong to
the existing open PR, rather than a separate implementation item.

The player's message follows in full:

> claude cloud's review is here (it cannot post comments):
>
> ## Summary
> Final adversarial review of the whole PR under **pr-review**: semantic correctness first, then code.
> **Semantic: what was checked**
> - **rosy-chipmunk** was read against cozy-pelican statements 1 to 11 and golden-otter ("only the latest save action matters"), and against its record and review item. Every statement is built:
>   - the symbol waits for the browser's answer;
>   - a change not kept is struck;
>   - the flush reconnects and retries once;
>   - there is no 100ms threshold;
>   - the symbol is fully shown for at least 1s, from when it appears;
>   - a strike is fully shown for at least 10s;
>   - deletions show the symbol, and a restart with nothing left to delete shows nothing;
>   - only the newest action decides plain or struck;
>   - opening a saved game writes only when it charged a day;
>   - the strike keeps signal red.
> - The 10s counted from the strike rather than from when the symbol appeared is longer than statement 6 asks, so it still meets "at least". The PR names it open to overturn, as it does the 5s timeout.
> - The picture (`docs/evidence/rosy-chipmunk-save-symbols-2026-10-02/save-symbols.png`) shows the plain and struck disks at 48px and 128px on both grounds. It is legible, and the struck SVG is `save.svg` plus two strokes, `#221f28` (`Palette.OUTLINE`) and `#e04a3f` (`Palette.SIGNAL_RED`). `membership.json` registers it on the `ui` group.
> - **frosty-pelican** was read against its record and the player's three quotes: "Let's do A and make the codex version always refuse", "Make it so it can be easily turned off and refuse again later…" and "Yes default to refusing".
>   - The switch defaults to refusing, and an ask happens only for `NAPPY_ASK_FOR_PLAYER_WRITES=1` in a cloud session or on a machine with no identity directory.
>   - `tools/codex-hooks.py` turns any decision a guard names into a deny with a refusal of its own.
>   - tall-egret's "Stop and tell me" is overturned only there, and the record says so.
> - **Queue:** neither item came from a queue entry. `docs/todo/2026-09-27-leafy-finch/write-guard.md` (the guard letting the inbox script write an issue) is still open work, and its text is still true.
> **Code: what was checked**
> - **Operation ids.** `GameSave._new_operation()` is called only for an announced change, never for a refused one. It is static, so it keeps growing across scene reloads. `write()` and `clear()` announce before the flush starts, and `_settle()` emits the matching `*_settled` signal with the same id.
> - **`SaveIndicator.Showing`:**
>   - The newest action decides in both arrival orders: an older failure after a newer success, and an older success after a newer failure.
>   - An unknown answer and a duplicate answer are each ignored, since `_unanswered.has()` guards both.
>   - A carried symbol keeps `_newest` across a reload, and a freshly built one ignores answers to changes it never began.
> - **`main._reload_the_scene()`** is the only reload, checked by grepping for `reload_current_scene`. It serves the held restart, the day-14 hand-over, the escape's replay and the `--start-escape` flag's replay, where the symbol is null and the carry does nothing. It unpauses before reloading. `_reload_override` is set only by tests.
> - **Timeout.** The 5s timeout counts frames clamped to 0.25s, on `SceneTree.process_frame`, which survives the reload and fires while the tree is paused.
> - **Opening a saved game.** `_write_dawn_for_a_resumed_run()` writes only for `day_under_way`. The symbol is raised before the charge in `_ready()`, and in `_ready_escape()` before anything writes.
> **What was run**
> - At the head, in a separate worktree with Godot 4.7.2:
>   - `tools/check.sh` passes.
>   - `tools/test.sh save main held_restart finale title orientation atlas telemetry`: 4426 checks, 0 failures.
>   - `tools/test_rules_hooks.sh`: 1801 checks, 0 failures.
>   - `tools/pycheck.sh` passes, including `tools/test_codex_hooks.py`.
>   - None of the hook suites has a quoted-script expansion case (finding 1).
> - The write guard was probed with about 110 command shapes. Each shape was fed to the hook as JSON from a script; nothing ran. The probes covered:
>   - a cloud session with the switch on;
>   - a cloud session with it off;
>   - a machine with identities;
>   - the same shapes against `origin/main`'s guard.
> - The ordinary shapes this workflow uses are all asked about with the switch on and none is wrongly denied: `git push origin <branch>`, `git push -u origin <branch>`, `git push origin <branch> 2>&1 | tail -1`, `git commit -q -F <file>`, and the heredoc `git commit -m "$(cat <<'EOF' …)"`.
> - Destructive or publishing shapes stay denied:
>   - tag pushes and `v*` refspecs;
>   - forced, deleting, mirroring and pruning pushes;
>   - `-c remote.origin.push=v1.2.0` and `=:feature/x`;
>   - `--config-env`;
>   - `gh pr merge`, `gh issue`, `gh pr review` and `gh api` writes.
> - **Anything destructive still answered "ask":** `git push origin HEAD:main`. The `main` ruleset requires a pull request, so it does not land.
> **Findings with no line to hang on**
> - *(nit)* The evidence folder `docs/evidence/rosy-chipmunk-save-symbols-2026-10-02/` is not cited by any file in the repo; only the PR description links it. **verify** asks for "the conclusion in the decision record and its evidence under `docs/evidence/`". Cite it, and its `render-sheet.gd` rerun command, in `docs/decisions/2026-10-02-rosy-chipmunk.md`'s Verified paragraph.
> **Verdict: not ready** against `4fed6bcb72a221d2af384137f5c8386965ca75bf`
> Review by a Claude Code agent.
> Inline comment on .claude/hooks/github-write-guard.sh:615 (blocking):
>
> **Blocking.** The new "expansion before the subcommand" deny does not see a substitution inside a quoted script.
> The PR closes `git -C $(pwd) push`, which used to slip past the guard entirely. The same shape inside `bash -c "..."` or `sh -c '...'` still slips past entirely: no deny and no ask, in a cloud session and on a machine with identities alike.
> I fed these to the hook only; nothing ran. Each returns no decision at all:
> - `bash -c "git -C $(pwd) push origin v1.0.0"`, a `v*` tag push, which deploys the site;
> - `bash -c "git -C \`pwd\` push origin v1.0.0"`;
> - `sh -c 'git -C $(pwd) push origin v1.0.0'`;
> - `bash -c "gh -R $(cat r) pr merge 3"`, a merge under the player's account with no prompt.
> The bare forms are denied, as are `bash -c 'git $(echo push) origin v1'` and `bash -c "git push origin v1"`.
> **Cause:** `opener_at` reads `$t.w0`. There, a `(` or backtick inside quotes has already become the soft marker U+0001, so the substitution is never seen as an opener. `after_options` then lets `-C` take the `$` word as its value, and the subcommand lands on the soft separator. The `($sub >= $n) or ($w[$sub] | is_sep)` branch returns null, so the push is never read. `detect_gh` (lines 856 and 865) has the same hole.
> The PR description and `docs/decisions/2026-10-02-frosty-pelican.md` both say this class is now denied, and neither lists the quoted-script form as an accepted gap.
> **Fix:**
> - In `detect_git`, deny when the subcommand position is a soft separator (`$t.w0[$sub] == "\u0001"`) and a commit-making or pushing word follows (`$t.lw > $sub`), with the same reason.
> - In `detect_gh`, deny when the noun or verb position is a soft separator.
> - Add those four commands to `tools/test_rules_hooks.sh` as denies, under all three environments.
> - Alternatively, list the form as an accepted gap in the header and in the record. That leaves an unprompted tag push and merge, which this PR exists to stop.
> Inline comment on .claude/hooks/github-write-guard.sh:539 (optional):
>
> **Optional.** `git -c push.default=matching push origin` is asked about with the switch on, reason `git push`. With `matching`, that push sends every local branch that has a namesake on the remote, which is a push of every branch. The record says a push of every branch is "never asked about, only denied", and its deliberate limits cover only a setting made by a separate `git config` command or through the environment.
> **Fix:** add `push.default` with the value `matching` to the pre-`push` config test, beside `followTags` and `mirror`, so it reads as a push of every branch. Or name inline `-c push.default=matching` among the record's deliberate limits.
> Inline comment on docs/decisions/2026-10-02-frosty-pelican.md:109 (nit):
>
> **Nit.** The list of accepted false denies names an output redirect to `"$LOG"`, but a plain redirect to a file whose name starts with `v` is denied too. `git push origin claude/x > v.log` is denied as a tag push, because the redirect target is read as a refspec. Either add it to the list, for example "an output redirect to a file whose name starts with `v`", or skip a word that follows `>` or `>>` in `push_scan`.
> Inline comment on docs/TELEMETRY.md:485 (nit):
>
> **Nit.** The table row ends: "a web deletion's own answer comes after the log is closed and is not logged". The same claim is at `docs/decisions/2026-10-02-rosy-chipmunk.md:174` and in `main._restart_run()`'s comment at `src/main.gd:2137`.
> That holds only until the next boot opens its own log. The case is a debug web export opened with `?telemetry=1`. That parameter turns the run log on there (`Telemetry._web_override_requested()`), and it is not one of `DevFlags._LIVE_DEBUG_QUERY_KEYS`, so saves still happen. On such a page, `_restart_run()` deletes the save and closes the log. The reload then calls `Telemetry.begin_run()` in the new `_ready()` within a frame. If the IndexedDB answer arrives after that, "the browser dropped the deleted save" is written at the top of the *next* run's log, about the run before it.
> **Fix:** say it may land in the next run's log. Or drop the note when no log was open at the time of the deletion, for example by recording on the pending entry whether a log was open.
> Inline comment on src/main.gd:2606 (nit):
>
> **Nit.** The doc says "Only a symbol that is up needs it; an idle one is freed with this node and the next boot builds its own." That is true only until the first carry.
> A symbol once handed to the tree's root stays there: `_raise_save_indicator()` adopts it through `SaveIndicator.carried()` and never moves it back under `main`. So at the next reload an idle symbol is not freed, and the next boot adopts the same one again instead of building its own. Behaviour is fine, since there is still exactly one symbol, but the sentence is false.
> **Fix:** say that a symbol already at the root stays there and is adopted again.
> Inline comment on docs/decisions/2026-10-02-rosy-chipmunk.md:209 (nit):
>
> **Nit.** The Not verified list still says the custom runtime keeps the unminified `FS`/`IDBFS` names only on the grounds that "its build passes no closure-compiler option, but the pinned source's default was not read". The PR description now lists "the closure compiler defaults off" among its source checks of the pinned 4.7.2, and the Codex reviewer confirmed it. The record and the description disagree. Update the record to say the default was read and is off, and keep only "the release export itself was not run" as unverified.
