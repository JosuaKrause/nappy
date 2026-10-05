# Playtest misty-newt — Encounters on the counter: seen, influenced, and how often she runs

2026-10-04. One note captured in the session, #574, its words said in a conversation about the
page's GoatCounter events (`VisitCounter`, listed in `docs/TELEMETRY.md`). Each of the player's
words is copied word for word, after what it answered.

## #574 — GoatCounter: per day, which events had a meaningful encounter and which were properly on screen

Said on 2026-10-04. The note holds two messages: the first was said unprompted, and the second
answers the assistant's reply to the first. The note keeps them as one text, so that reply
comes here before both.

The reply to the first message said it is not overkill: every source already tracks what it lands
on her excitement meter (`EventInstance.accumulate_landed()`, which the crying-loss cause and the halos
read), and the pelican's `nappy-day-N-pelican-excited` already fires on its first share. On the
number of distinct names: at most 14 days × about 57 sources (53 catalogue rows plus `pelican`,
`crowd`, `traffic` and `self`), about 800, far fewer in practice because each day only meets its
act's rows, and at most one GoatCounter call per source per day. It proposed
`nappy-day-N-influenced-<source>` (hyphens like every other GoatCounter event), once per row per
day, sent the first time that row's total landed on her that day passes a threshold, proposed as
10% of a full meter, one constant. It added: "A day lost to crying still names its main cause as
it does today; the influence events add who else contributed." — the "loss" the second message
refers to. And it asked: "Should I file it into the queue with the 10% threshold, to start after
the patch release?"

> would it be overkill to have telemetry for being influenced by an event? just a binary yes if the influence of the event reached a certain threshold. I want to avoid creating too many distinct event but it should be of the form day_x_influenced_by_y
>
> I'm not talking about loss I'm talking about whether an event had a meaningful encounter with the event also let's add another set with whether it was (fully; or reasonably) visible on screen (just a part or too far off the edge doesn't count)

The second set is an event counted as seen only when it is wholly or mostly on screen, not when
just a part shows or it is too far off the edge.

The assistant read the note back. "Influenced", `nappy-day-N-influenced-<event>`: once per event type
per day, the first time it has a meaningful encounter with her, regardless of how the day ends.
"Seen", `nappy-day-N-seen-<event>`: once per event type per day, the first time an instance is
properly on screen, proposed as at least about 80% of what is drawn for it inside the view; a
sliver at the edge, or only its halo or warning badge, does not count. The fork it asked: what
counts as a meaningful encounter? **(a)** excitement only — the event landed at least 10% of a
full meter on her that day, which misses a roadblock she detoured around, a robber chase, a dog
she outran. **(b)**, the assistant's pick: excitement, or it acted on her — (a), plus a
lethal-on-contact event she came within catch distance of, a pursuer that chased her, a blocker
that sat on her planned path and she walked another way. And the smaller question: keep
`nappy-day-3-seen-fire` and `nappy-day-N-pelican-seen` as they are beside the new set (the
assistant's pick), or drop them.

> I want to establish two things -- how frequent do certain events actually appear and are players avoiding them or ignoring them?

The assistant noted that with one event per event type per day, "how frequent" means the share of
days on which it appeared, not how many times per day (two dogs on one day count once); the
alternative it offered was one seen event per instance, more GoatCounter calls but still small,
"only for the events you care most about". It also read the goal back: seen ÷ day-N-began is how
often it appears; seen without influenced is avoided; seen and influenced is ignored; a
"meaningful encounter" is at least 10% of a full meter landed for an exciting event, else within
its catch distance or chased; influenced but never seen is an influence from off screen.

> don't send only once per day

The assistant read that back: every event instance sends its own events — `seen-<event>` the
first time that instance is properly on screen, `influenced-<event>` the first time that instance
alone reaches the threshold (10% of a full meter, or within its catch distance, or it chases her);
two dogs on one day send two of each. And it asked whether ordinary walkers, cars (hundreds a day,
not events) and her own running stay out, counting only the event types, the pelican included.

> I can have three interactions with a yeller -- as long as they're a bit apart from each other those are distinct interactions -- if it's a different yeller it's definitely a distinct interaction

The assistant proposed a meaning for "a bit apart": an instance's interaction ends after 5 seconds
in which it lands nothing on her meter (the excitement halo's own window, `ExcitementHalo.WINDOW`),
so one yeller passed three times sends three `influenced-homeless-yeller`. And it asked two
questions: (1) should `seen` use the same rule — seen again once off screen at least 5 seconds and
back (the assistant's pick: yes); (2) leave out ordinary walkers, cars and her own running,
counting only events, the pelican included (the assistant's pick: leave them out).

> I would define the gap as left the screen and encountered again at a later time (eg 5s). this should also apply to seen. we can ignore regular walkers and cars unless there is a good way to measure them. mostly I'm interested in the ratio of interacted/seen

The assistant then read the whole spec back: one encounter per instance coming on screen, ended by
leaving it, counted again if back at least about 5 s later; `nappy-day-N-seen-<event>` once per
encounter at about 80% in view; `nappy-day-N-influenced-<event>` at most once per encounter at 10%
of a full meter, or within catch distance, or chased; the readout influenced ÷ seen per event
type, printed by `tools/goatcounter.sh`; ordinary walkers and cars left out. Earlier it had also
proposed leaving out her own running (`self` in the crying-loss cause: her own running and
standing in an alley), "her running isn't an encounter with anything".

> we can count the number of running excluding gaps smaller than 10s

The assistant read the running count back: `nappy-day-N-ran`, one event per bout of running, a
restart less than 10 seconds after stopping being the same bout, sent when the bout begins whether
or not the run excites the baby. And it asked: "Should I file #574 with the next batch, to be
built after the patch release?"

> yeah we can start it for the next patch.

## Routing

1. **#574** → [spry-llama, the counter counts encounters: seen, influenced, and bouts of
   running](../todo/2026-10-04-spry-llama/README.md), band `now` from the player's "yeah we can
   start it for the next patch."
