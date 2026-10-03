# striped-lark — Deny unreadable xargs pushes · 2026-10-02

**Source.** [silver-panda, the merged save PR review finds an unreadable xargs
push](../playtests/2026-10-02-silver-panda.md) records the supplied independent
delta review and the player's request to fix review issues. The player merged
PR448 while that review was being handled, so this correction has its own PR.
It preserves [frosty-pelican, identity-less write prompts](2026-10-02-frosty-pelican.md)'s
contract that a publishing push or a push unreadable to its end is refused.

**Built.** `echo v1 | xargs -I{} git push origin {}` and `xargs git push origin
< tags.txt` no longer reach an ordinary branch-push prompt. Input can append or
replace arguments with release refspecs absent from the hook JSON, so an
unwrapped push invoked through xargs is classified as unreadable and denied.
The hook header names this behavior and its identity-wrapper exemption.

A single forward pass records xargs context for the existing token and quote
tables. Its command context ends at the enclosing command's separator, while a
separator inside the script xargs invokes keeps that context. This catches a
later push inside `xargs sh -c 'git status; git push origin'` without treating a
separate push after `xargs git status;` as input-driven. The table is built only
when an xargs word occurs. It adds linear work, not a backward scan per git word.

**Choices open to overturn.** All unwrapped xargs pushes are conservatively
denied, including an ordinary branch named in the written command, because input
can add refspecs. Literal mentions of xargs count, matching the guard's existing
conservative treatment of git mentions. In an uncertain quote reading, soft
separators retain context; a later unrelated push in that script can therefore
also be denied. The alternative of prompting despite unreadable input was
rejected because it permits publishing under the player's identity.

**Preserved.** Readable xargs reads remain allowed; direct opt-in branch pushes
and pushes after a separate xargs read still ask where the existing policy allows
it. Coder identity wrappers remain exempt, including xargs outside or inside the
wrapper; reviewer wrappers cannot push. Default-off, configured-identity and
Codex refusal behavior remain unchanged. The Codex adapter needs no payload,
tool-name or event change because this change is internal guard classification.

**Verified.** All candidate commands were submitted as hook JSON and never
executed. The two source cases ask against the pre-fix guard and deny against
the implementation. Regression cases cover xargs argument/file options, nested
environment and timeout wrappers, quoted scripts, separators, readable commands
and identity wrappers. `tools/test_rules_hooks.sh` passes with 2,284 checks and
zero failures; `tools/test_codex_hooks.py` passes all 57 tests. `tools/check.sh`,
`tools/lint.sh` and whitespace checks pass. No local full game suite or windowed
capture was needed for a development guard change.

**Limits.** This remains a bounded development guardrail, with the existing
accepted shell-parser gaps. It is not a shell interpreter or a security boundary.
The supplied review's obsolete `$[...]` arithmetic observation explicitly asks
for no change; this item does not change that syntax or gameplay/save code.
