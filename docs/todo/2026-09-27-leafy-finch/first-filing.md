**Issue #423 ("shadows are misplaced", `queue_next`) is the inbox's first real filing**
([dotted-quail](../../playtests/2026-09-27-dotted-quail.md), statement 3: "you can use this to test
the implementation" · "as a first real test"). When the player triggers it, `tools/inbox.py` files
it end to end as a filing PR of its own: the note's current text word for word in a new playtest
file, a queue entry in band `next`, the description's `Filed from #423`, the PR opened as
`claude-orchestrator`, and the note closed by `tools/inbox.py close --pr <P>` right after. The code
PR that built the inbox never files it ([velvet-otter](../../playtests/2026-09-27-velvet-otter.md):
"the test of 423 shouldn't happen in a code PR" · "I will trigger it when everything is merged").
