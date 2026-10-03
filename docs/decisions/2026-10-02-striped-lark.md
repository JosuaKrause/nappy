# striped-lark — Deny unreadable xargs and GNU parallel pushes · 2026-10-02

**Source.** [silver-panda, the merged save PR review finds an unreadable xargs
push](../playtests/2026-10-02-silver-panda.md) records the supplied independent
delta review and the player's earlier authorization for PR448 follow-ups. The player merged
PR448 while that review was being handled, so this correction has its own PR.
It preserves [frosty-pelican, identity-less write prompts](2026-10-02-frosty-pelican.md)'s
contract that a publishing push or a push unreadable to its end is refused.

[grassy-yak, input-driven push review corrections](../playtests/2026-10-03-grassy-yak.md)
records the next review and the player's instruction: "let's do parallel the fix is
reasonably sized". GNU parallel receives the same input-context handling as xargs.

[cozy-alpaca, input-supplied subcommands and wrappers](../playtests/2026-10-03-cozy-alpaca.md)
records the subsequent review. Input can supply the subcommand too: missing,
separator or nonplain lowercase git subcommands and gh nouns/verbs now fail closed.
The same policy covers `gxargs` and `env_parallel`. GNU parallel forwards command
position through its documented argument-taking options, including `--colsep`; a
punctuation-only delimiter retains its token position so a later `cat` stays a read.

**Built.** `echo v1 | xargs -I{} git push origin {}` and `xargs git push origin
< tags.txt` no longer reach an ordinary branch-push prompt. Input can append or
replace arguments with release refspecs absent from the hook JSON, so an
unwrapped push invoked through xargs or GNU parallel is classified as unreadable and denied.
This includes `echo v1 | parallel git push origin`, `parallel git push origin {} < t`
and `ls | parallel -j1 git push origin {}`.
The hook header names this behavior and its identity-wrapper exemption.

A single forward pass records xargs/GNU parallel context for the existing token and quote
tables. Its command context ends at the enclosing command's separator, while a
separator inside the script xargs invokes keeps that context. This catches a
later push inside `xargs sh -c 'git status; git push origin'` without treating a
separate push after `xargs git status;` as input-driven. The table is built only
when an xargs or parallel word occurs. It adds linear work, not a backward scan per git word.

**Choices open to overturn.** All unwrapped xargs/GNU parallel pushes are conservatively
denied, including an ordinary branch named in the written command, because input
can add refspecs. Literal mentions of xargs or parallel count, matching the guard's existing
conservative treatment of git mentions. In an uncertain quote reading, soft
separators retain context; a later unrelated push in that script can therefore
also be denied. The alternative of prompting despite unreadable input was
rejected because it permits publishing under the player's identity.

An unreadable input-driven gh command is also treated as potentially merging a PR,
so a reviewer wrapper refuses it; a coder wrapper remains exempt. This conservative
choice is open to overturn. The alternative would allow input to hide `pr merge`.

**Preserved.** Readable xargs/GNU parallel reads remain allowed; direct opt-in branch pushes
and pushes after a separate xargs/parallel read still ask where the existing policy allows
it. Coder identity wrappers remain exempt, including either input wrapper outside or inside the
wrapper; reviewer wrappers cannot push. Default-off, configured-identity and
Codex refusal behavior remain unchanged. The Codex adapter needs no payload,
tool-name or event change because this change is internal guard classification.

**Verified.** All candidate commands were submitted as hook JSON and never
executed. The two source cases ask against the pre-fix guard and deny against
the implementation. Regression cases cover xargs argument/file options, nested
environment and timeout wrappers, quoted scripts, separators, readable commands
and identity wrappers. The three parallel reproductions each ask in both opt-in
cloud and unconfigured environments before the correction, producing six failures
in the expanded suite; all deny afterward. `tools/test_rules_hooks.sh` passes with 2,330 checks and
zero failures; `tools/test_codex_hooks.py` passes all 57 tests. `tools/check.sh`,
`tools/lint.sh` and whitespace checks pass. No local full game suite or windowed
capture was needed for a development guard change.

The latest expanded regression suite found 238 failures across 2,771 checks against
the prior implementation, including all six missing-subcommand examples. After the
fix and punctuation-read regression, all 2,793 checks pass, as do all 57 adapter tests,
shell syntax, lint and whitespace. Test payloads were never executed as shell writes.
Main reconciliation ed3acd0 preserved incoming CI costs and the merged recipe design;
base 6006fa69, prior head cba913ae, incoming main 746e7b3f. Boot checks passed.

The independent final review at 790881cc found two remaining in-scope gaps:
[arbitrary lowercase replacement markers](https://github.com/JosuaKrause/nappy/pull/453#discussion_r4171808745)
can replace a command spelled like a literal read, and
[ordinary parallel option values](https://github.com/JosuaKrause/nappy/pull/453#discussion_r4171808747)
can hide a publishing script's command position. The player's incorporation request
includes fixing these findings in this PR.

The wrapper context now carries a stack of active replacement tokens. Attached and
separate replacement forms, including aliases, make a git/gh noun or verb containing
the token unreadable even when its spelling is lowercase or matches a known read.
Nested wrappers retain the enclosing context; readable command boundaries end it.
The argument tables cover the reviewed parallel value-taking options and aliases,
including maximum arguments/processes, job logs, delay and halt behavior, plus BSD
xargs value options. No adapter contract changes.

Optional replacement syntax retains both command-position interpretations: the
generic table keeps the default-marker reading and the wrapper table can consume
a following marker. This conservative choice, open to correction, avoids allowing
an unreadable command merely because one interpretation resembles a read.

The expanded regression matrix produces 209 failures against the preceding hook.
With the correction, all 3,152 hook checks and 57 adapter tests pass; shell syntax,
lint, whitespace and headless boot pass. The tests cover the exact review cases,
replacement aliases, read-shaped markers, nested context, punctuation-only values,
reads, command boundaries and identity exemptions/refusals. All candidate commands
remain JSON inputs to the hook and are never executed as publishing payloads.

**Limits.** This remains a bounded development guardrail, with the existing
accepted shell-parser gaps. It is not a shell interpreter or a security boundary.
The supplied review's obsolete `$[...]` arithmetic observation explicitly asks
for no change; this item does not change that syntax or gameplay/save code.

The review's Python f-string command, dynamically found executable and stdin-loop
refspec gaps are filed separately as quiet-tapir, remaining dynamic command writes;
they are pre-existing gaps outside this correction, not claims of covered syntax.

## Shared option consumption · 2026-10-03

The independent review at 9b57ce74 found that the two option scans still disagreed:
`xargs -rIstatus` did not mark the read-shaped replacement token, and a consumed
`-E -Iother` value could be misread as a new replacement option. Parallel options
`--timeout`, `--retries` and `--results` could also conceal a publishing script's
command position. Those findings are fixed inside the same PR.

One bounded parser now supplies command position and replacement context. It handles
clustered short options and consumes known option values exactly once. Unknown flags
or abbreviations mark the wrapper unreadable, conservatively denying git/gh and
publishing-script mentions, including apparent reads or dry runs, until the wrapper
boundary. This deliberate false-denial choice is open to correction; guessing unknown
arity would retain the write bypass. Known reads, enclosing command boundaries, coder
exemptions and reviewer refusals retain their existing policy.

GNU Parallel `-l`/`--max-lines` are optional numeric line counts, not replacement
aliases; the preceding implementation's alias interpretation was wrong. Parallel `-I`
requires a replacement argument and `-i`/`--replace` accept an optional one. GNU xargs
optional values are attached-only, while a following non-option remains conservatively
tracked as a possible replacement marker without being consumed. Parallel consumes a
following optional value. Malformed or ambiguous attached forms remain unreadable.

The 48 new focused hook-JSON cases expose 31 failures at 9b57ce74 and all pass with
the shared parser. Shell syntax, lint, whitespace and headless boot pass. The first
full matrix printed 3,582 successful checks and no failed assertion, but exited in its
footer after the author edited header comments while Bash was reading the file. A
frozen-copy rerun passes all 3,582 checks with zero failures and exit 0. The adapter run's
56 other tests pass; its dense-option-chain test had five timing subcase failures while
the matrix ran concurrently, then passed all six subcases in isolation (10.08 seconds
for that test). These are recorded as verification conditions, not guard behavior
failures or a claim that the first whole run exited successfully. The Codex adapter's
tool names, payloads and decision contract remain unchanged. No publishing payload
was executed; all examples were JSON inputs to the hooks.

## The review at 8aa2e1b8 · 2026-10-03

claude-reviewer's review of that head and the player's own review comment left findings that
the same PR fixes.

**Input can supply a release's own `push`.** `tools/release.sh` tags and publishes only with a
second `push` argument, and input appends arguments: `echo push | xargs tools/release.sh patch`
runs `tools/release.sh patch push`. Under an active xargs or GNU parallel context the script is
therefore a write whether or not `push` is written, and it is denied, never asked about. Input can
only add words, never remove one, so `land-prs.sh` and `update-pr.sh` with a written `--dry-run`
stay reads.

**An escaped separator is an option's value, not a command boundary.** A backslash-escaped `\;`,
`\|` or `\&` written as a word of its own outside quotes is an argument to the shell, so `xargs
-d \; git push origin` delimits input with `;` and pushes whatever it reads. The guard read that
word as a soft separator: the input context ended there, the push after it was asked about, and
`printf 'push;origin;v1' | xargs -d \; git` was allowed. A soft separator now ends an input
wrapper's context only inside a quoted script, deeper than the wrapper's own words, and only a
hard separator leaves an option without its value. `xargs -d \; git status` stays a read, and a
push in a separate command after `xargs git status;` is still asked about.
