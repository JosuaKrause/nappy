# The dog sprinkle probe stops on a null in the director's queue

`tests/probes/m96_dog_sprinkle.gd` measures how often the sprinkled charging dog, the dog the event
director puts at the front of its queue on a day past the teaching day at a fixed chance
(`EventDirector.CHARGING_DOG_SPRINKLE_CHANCE`), is offered and then met over a whole run of
continuous walking, on eight seeds. It counts "offered" by looping over the director's private queue
of owed events (`EventDirector._owed`) and reading each entry's `id`.

**Its first failure:** that queue now holds a `null` for each event the day owes her route, a marble
from the route's bag whose row is decided when it is handed out (the comment on `_owed` in
`src/events/event_director.gd`), so the probe's `queued.id` is read on a null and the run stops on
the first day that owes her route anything (the record 2026-10-18-minty-quail-lilac-chipmunk).

*Proposed, not asked for:* the plainest fix skips the nulls (`queued != null` before `queued.id`),
which keeps "offered" (the die rolled a hit, read off the queue at dawn) apart from "met" (the
director handed the dog out through `due()` before the day ended), the gap the probe measures, but
keeps its read of the director's private queue. A fix that reads no private member needs the
director to say what it owes through a method a game class also calls, which none does today, so
that half is open. Or the probe is deleted, the rate's measurement and the reason it was chosen
standing in M96's records (the teaching day and the dog after it, `tools/decisions.sh M96`).
