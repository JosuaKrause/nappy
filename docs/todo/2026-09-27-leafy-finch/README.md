priority: now

# leafy-finch — Issues as the inbox, and CI takes the mechanical review · filed 2026-09-27

> "the important thing is that it ends up in a safe queue in issues and I can choose when we want
> to turn those into a doc update PR"

> "what I want is a CI check that does what the reviewer currently does automatically. we should
> get as close as possible to that. the reviewer still needs to verify the correctness of those
> changes anyway. the CI is only a help"

[bouncy-heron](../../playtests/2026-09-27-bouncy-heron.md), statements 1 to 24, and
[dotted-quail](../../playtests/2026-09-27-dotted-quail.md) hold every word of it. **The queue,
the review items, the playtest files and the decision records stay in the repository**, because an
entry is reviewed when it enters the queue and a misread statement is cheaper caught there than
built (statement 1). **GitHub Issues become the player's inbox and nothing else**: a note there is
safe the moment it is written, can be edited until its filing PR is opened, and an agent turns a
batch of notes into one filing PR when the player asks (statements 5, 6, 22). The CI that checks a filing
([leafy-finch-2](../../decisions/2026-09-27-leafy-finch-2.md)), the `claude-orchestrator` identity
the scripts write as ([leafy-finch](../../decisions/2026-09-27-leafy-finch.md)) and the inbox
itself, its skill, capture and write guard
([leafy-finch-3](../../decisions/2026-09-27-leafy-finch-3.md)), are built. What is left is the
inbox's first real filing, issue #423, when the player triggers it (`first-filing.md`).

The band is `now` by the player's word ([plaid-tapir](../../playtests/2026-10-03-plaid-tapir.md),
statement 1: "once this is merged we will do the first issue ingestion using its new script").
