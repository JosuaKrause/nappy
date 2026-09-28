# Playtest dotted-quail — Questions about a note are asked on its issue

2026-09-27. Said in conversation, after leafy-finch (Issues as the inbox, and CI takes the
mechanical review) was filed and merged. That entry makes an open GitHub issue carrying the `inbox`
label the player's note, filed into the queue as a batch when the player asks.

## Statements

> "oh, also if you need more info you can also ask in the github issue. so by the time we queue a
> task most questions are already resolved"

1. **An agent that needs more from a note asks on the note's own issue**, before it is filed, so
   that most questions are settled by the time the work is queued. → leafy-finch.

The player then opened the first inbox note, an issue with the `inbox` label and a band label, and
said:

> "I created an issue with inbox label and with priority I choose the convention of queue_now,
> queue_next, queue_later, and queue_parked"

2. **The band labels are `queue_now`, `queue_next`, `queue_later` and `queue_parked`**, and the
   player has created them on the repository. They replace the filer's proposed `band: now` names.
   → leafy-finch.

The note is issue #423, "shadows are misplaced", labelled `inbox` and `queue_next`. The player
added:

> "you can use this to test the implementation"

> "as a first real test"

3. **Issue #423 is the inbox's first real test**: the PR that builds the inbox skill files it with
   the new tools, end to end. → leafy-finch.
