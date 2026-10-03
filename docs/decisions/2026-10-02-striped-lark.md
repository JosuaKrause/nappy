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

**Limits.** This remains a bounded development guardrail, with the existing
accepted shell-parser gaps. It is not a shell interpreter or a security boundary.
The supplied review's obsolete `$[...]` arithmetic observation explicitly asks
for no change; this item does not change that syntax or gameplay/save code.
