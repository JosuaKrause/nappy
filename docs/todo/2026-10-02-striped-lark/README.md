priority: now

# striped-lark — Deny unreadable pushes supplied through xargs · filed 2026-10-02

The supplied delta review of merged PR448 reports that `echo v1 | xargs -I{} git push
origin {}` and `xargs git push origin < tags.txt` ask instead of refusing in an opted-in
identity-less/cloud session. Input supplies refspecs the hook cannot see, including release
tags, despite the contract that publishing pushes stay denied. The full source and pickup
context are in [silver-panda, the merged save PR review finds an unreadable xargs push](../../playtests/2026-10-02-silver-panda.md).

This is a new focused follow-up because the player merges448 while its delta review is
being handled. It changes the development write guard, not the released game. The source
contract is [frosty-pelican, identity-less write prompts](../../decisions/2026-10-02-frosty-pelican.md).

**Proposed, not asked for:** the `now` band reflects the current request to fix review
issues. Classify a push invoked through xargs as unreadable and refuse it in every context,
preserving readable commands and current identity/prompt policy. This conservatively denies
ordinary xargs pushes too, since their extra arguments come from input. The alternative
is accepting an unknown publishing gap; it is not chosen. The review's obsolete `$[...]`
arithmetic observation explicitly requests no change and remains outside this item.
