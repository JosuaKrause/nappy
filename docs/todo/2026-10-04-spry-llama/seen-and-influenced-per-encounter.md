**Every encounter with an event instance sends a seen event and, when it was meaningful, an
influenced event.** Ordinary walkers and cars send nothing. Each instance keeps its own encounter:
it begins when the instance comes onto the screen and ends when it has left; the same instance
coming back counts as a new encounter only when it is encountered again at a later time, about
5 s after it left, one constant. A different instance is always its own encounter. Within one
encounter the seen event is sent at most once, the first moment the instance is properly on
screen, and the influenced event at most once, the first moment the encounter is meaningful.

*Proposed, not asked for:* the names are `nappy-day-N-seen-<event>` and
`nappy-day-N-influenced-<event>`, `<event>` being the catalogue row's id hyphenated, as the
`lost-hard-fail-*` names already are (`charging_dog` is `charging-dog`), and a pelican counted as
`pelican` rather than its row's `cyclist`. Properly on screen is at least about 80% of what is
drawn for the instance inside the view, rather than the one-point test `EventManager._is_on_screen()`
makes. A meaningful encounter is at least 10% of a full meter landed on her by that instance within
the encounter (one constant), or, for a row that does not excite, coming within its catch distance
or being chased by it (`EventBus.pursuit_began`). The encounter's total needs a running sum of its
own, reset when a new encounter begins: `EventInstance.accumulate_landed()` keeps only the shares
inside the halo's 5 s window (`ExcitementHalo.WINDOW`), so its `landed()` cannot say what a longer
encounter landed. An influence from an instance that was not seen in that encounter is sent under
its own name, `nappy-day-N-influenced-unseen-<event>`, so influenced ÷ seen counts only encounters
she could see; the plainer alternative is one influenced name for both, which mixes the off-screen
ones into the ratio.

Open for whoever picks it up, each a question for the player: whether the pelican is counted
(proposed: yes, as `pelican`); whether `nappy-day-3-seen-fire` and `nappy-day-N-pelican-seen` stay
beside the new set (proposed: they stay unchanged); and what "within its catch distance" means for
a lethal row, whose reach ends the day, so a near miss there needs a distance of its own or counts
only through the meter. The new signals are listen-only, as every signal that exists for
`VisitCounter` is. `docs/TELEMETRY.md` lists the new names in the same pull request.
