**A PR that changes code also changes the queue and the decision records** (statement 10). When
the diff touches anything under `src/` or `tests/`, CI fails unless it also deletes or rewrites a
file under `docs/todo/` and adds or changes a file under `docs/decisions/`. This is the committing
skill's standing rule — "a work item never merges while its queue item is unresolved", the item's
file gone and its record filed — made a check rather than only a reviewer's memory.

A PR with no queue item behind it, such as a CI or tooling repair, says so in its description with
a line `No queue item: <reason>`, which passes the check and which the reviewer judges.

**Proposed, not asked for:** the escape line's exact form.
