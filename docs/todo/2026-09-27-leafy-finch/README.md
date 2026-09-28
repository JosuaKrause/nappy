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
batch of notes into one filing PR when the player asks (statements 5, 6, 22). What is left is that
inbox: the skill and script that read and file it (`inbox-skill.md`), the capture script
(`capture.md`), and the write guard that lets those scripts, and only them, write an issue
(`write-guard.md`). The CI that checks a filing
([leafy-finch-2](../../decisions/2026-09-27-leafy-finch-2.md)) and the `claude-orchestrator`
identity the scripts write as ([leafy-finch](../../decisions/2026-09-27-leafy-finch.md)) are built.

The band `now` is the filer's reading of "once that PR merges you can start implementing"
(statement 15); the player named no band.

**What this changes that is already written down.** The **playtest-feedback** skill's "write it
down before doing anything about it" gains the inbox as the first place words are written.
`.claude/hooks/github-write-guard.sh`, the hook that denies a GitHub write outside an agent
identity (the tall-egret record, "Each agent posts on GitHub as an app of its own"), changes for
issue writes (statement 14), and the Codex adapter `tools/codex-hooks.py` and its tests change with
it if the change needs a new tool name, payload field or hook event, as `CLAUDE.md` requires.

**The PR that closes this entry writes its decision record**, which also records that Issues were
weighed as the queue itself and rejected — no review when an entry enters, edits with no reviewed
history, no path-triggered rules — and adopted as the inbox only.
