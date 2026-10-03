# Playtest amber-wombat — Keep every scene revision in PR 457

2026-10-03.

While the assistant incorporates the numbered scene feedback, disables automatic event
selection in authored recipes, and corrects the gate orientation using existing artwork,
the player reiterates the PR scope:

> do all changes inside 457 do not create new PRs for the work

They then ask about the separate builder and trailer-scene extraction PRs:

> what is the purpose of 458 and 460?

The assistant explains that #458 extracts the scene builder and power-station examples,
and #460 extracts the scripted trailer scenes. Splitting the queue entries into PRs was
the assistant's mistake, already identified in
[rosy-lark, queue entries are not separate PRs](2026-10-03-rosy-lark.md).
Both extraction PRs are closed, with their branches preserved; the implementation and
all scene revisions remain in #457.
