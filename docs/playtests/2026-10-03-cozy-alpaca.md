# Playtest cozy-alpaca — Input-supplied subcommands and parallel wrappers

2026-10-03.
# Review source

The player asked to revisit #453's comments. The following is the latest review,
from https://github.com/JosuaKrause/nappy/pull/453#issuecomment-5965444653.

> ## Review of PR 453 — Deny unreadable pushes supplied through xargs and GNU parallel
> Head: cba913ae7c5518efe2c01923fdccc29b3c36483e
>
> Summary
> The PR does what the source review and the player asked: an xargs or GNU parallel push whose
> refspecs come from input is denied rather than asked about. The three parallel reproductions are
> denied, and reads and separate later pushes keep their behavior. The claims hold:
>   - 2,330 hook checks pass at head.
>   - The new tests fail 6 times against the previous hook, exactly the three parallel cases in
>     both opt-in settings.
>   - 57 Codex adapter tests pass.
>   - CI is green, and the branch merges cleanly into current main.
> But the PR's own principle, "input may supply push refspecs absent from the hook JSON", applies
> equally when input supplies the git or gh subcommand itself. Those commands are not asked about;
> they are allowed outright, on every machine. That makes the decision record's central sentence
> false.
>
> ── BLOCKING ─────────────────────────────────────────────────────────────
>
> 1. When input supplies the subcommand, the write is allowed with no decision at all
>    .claude/hooks/github-write-guard.sh:666 · docs/decisions/2026-10-02-striped-lark.md:16-17
>
>    - The line `elif ($sub >= $n) or ($w[$sub] | is_sep) then null` makes a git with no
>      readable subcommand count as no write. detect_gh does the same.
>    - The new input-context pass (xargs_context, which marks every word that follows xargs or
>      parallel) is consulted only after the subcommand has already been read as `push`.
>    - So when input supplies the subcommand, the guard sees `git` with nothing after it and
>      returns nothing.
>    - Allowed on both a cloud session and a machine with identities:
>        echo push origin v1 | xargs git           (pushes tag v1, which deploys the site)
>        echo push origin v1 | parallel git
>        echo push | xargs -I{} git {} origin v1
>        echo commit -m x | xargs git
>        echo merge 3 | xargs gh pr                (merges PR 3)
>        echo pr merge 3 | xargs gh
>    - These were allowed on the base too, so the PR did not cause them. But the record says "an
>      unwrapped push invoked through xargs or GNU parallel is classified as unreadable and
>      denied", which is false for them.
>    - The frosty-pelican record (identity-less write prompts) already denies
>      `git $(echo push) origin v1`, a subcommand that is itself an expansion. `{}` from xargs is
>      the same shape.
>
>    Fix: inside input context, deny a git whose subcommand is missing, a separator, or not a
>    plain lowercase word (^[a-z][a-z-]*$, which catches {}, % and REF) as "git push that cannot
>    be read". Deny a gh whose noun or verb is missing the same way. Add the six commands above to
>    the write_guard_never_asked tests. Or, at minimum, list the shape under "Limits" in the
>    striped-lark record and narrow the sentence at :16-17.
>
> ── NON-BLOCKING ─────────────────────────────────────────────────────────
>
> 2. parallel is not a wrapper word, so pushing tools/ scripts run under it are allowed outright
>    github-write-guard.sh:418 (wrapper_words, the words that pass command position on to the
>    next word) · :348 (wrapper_argument_options, which wrapper options take a separate argument)
>
>    - Pushing scripts are caught only in command position. After parallel, the script name is
>      not in command position.
>    - `ls | parallel tools/release.sh patch push` is allowed on both a cloud session and a
>      machine with identities, and the same holds for tools/land-prs.sh, tools/update-pr.sh and
>      tools/prune-merged.sh.
>    - The xargs form is denied.
>    - The player asked to treat parallel like xargs: "let's do parallel the fix is reasonably
>      sized".
>
>    Fix: add "parallel" to wrapper_words, and its argument-taking options (-j/--jobs,
>    -a/--arg-file, -I, -n, -N, -L, -S/--sshlogin, -d, --colsep) to wrapper_argument_options. Name
>    it in the header's wrapper list and add one never-asked test.
>
> ── NIT ──────────────────────────────────────────────────────────────────
>
> 3. Exact name matching misses GNU variants
>    github-write-guard.sh:466, :1024 (named("xargs") or named("parallel"))
>
>    - `echo v1 | gxargs -I{} git push origin {}` and `echo v1 | env_parallel git push origin`
>      are asked about in a cloud session, not denied.
>    - gxargs is what Homebrew's GNU findutils installs on a Mac; env_parallel ships with GNU
>      parallel.
>
>    Fix: also match gxargs and env_parallel, or list them under "Limits".
>
> ── OUTSIDE THIS PR (file separately; same on base) ─────────────────────
>
> - python3 -c 'import os; os.system(f"git push origin v1")' is allowed: once the quote is dropped,
>   the f-string prefix fuses into "fgit". The git-grep guard handles f-strings; the write guard
>   does not.
> - $(which git) push origin v1 is allowed.
> - A python loop over stdin filling a push refspec is only asked about, the same class as xargs.
>
> ── CHECKED ──────────────────────────────────────────────────────────────
>
> - Semantic:
>     - silver-panda and grassy-yak read, including "let's do parallel the fix is reasonably
>       sized".
>     - The frosty-pelican contract is kept: publishing or unreadable pushes are denied; branch
>       pushes, commits and PR writes are asked about; asking is off by default.
>     - The conservative false denials are marked open to overturn.
> - Queue: striped-lark was filed and removed on this branch, the net diff touches nothing in
>   docs/todo/, and the names are unique.
> - The player's earlier findings 2-4 are addressed.
> - Codex adapter: tools/codex-hooks.py passes the command through unchanged; no tool name,
>   payload or event changed, so it needs no update.
> - About 110 bypass and false-positive probes were sent as hook JSON only:
>     - Denied correctly: xargs and parallel options, renamed or quoted xargs, subshells, nested
>       scripts, find -exec.
>     - Still asked about correctly: separate pushes after ; && |, branch names containing
>       "parallel", PARALLEL=4.
>     - Still allowed correctly: xargs git status, parallel ruff check.
>
> Verdict: NOT READY — cba913ae7c5518efe2c01923fdccc29b3c36483e
> Finding 1 needs the detector fix, or at minimum a "Limits" entry and a corrected sentence in
> the striped-lark record.
