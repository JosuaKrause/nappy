**Every encounter with an event instance sends `nappy-day-N-seen-<event>` and, when it was
meaningful, `nappy-day-N-influenced-<event>`.** `<event>` is the catalogue row's id hyphenated, as
the `lost-hard-fail-*` names already are (`charging_dog` is `charging-dog`), and `pelican` for a
pelican rather than its row's `cyclist`. Ordinary walkers and cars send nothing.

Each instance keeps its own encounter: it begins when the instance comes onto the screen and ends
when it has left; the same instance coming back counts as a new encounter only after it has been
off screen for about 5 s, one constant. A different instance is always its own encounter. Within
one encounter `seen` is sent at most once, the first moment the instance is properly on screen,
and `influenced` at most once, the first moment the encounter is meaningful.

*Proposed, not asked for:* properly on screen is at least about 80% of what is drawn for the
instance inside the view, rather than the one-point test `EventManager._is_on_screen()` makes. A
meaningful encounter is at least 10% of a full meter landed on her by that instance within the
encounter (one constant, read from `EventInstance.accumulate_landed()`'s own record), or, for a row
that does not excite, coming within its catch distance or being chased by it
(`EventBus.pursuit_began`). An influence from an instance that was not seen in that encounter is
sent under its own name, `nappy-day-N-influenced-unseen-<event>`, so `influenced` ÷ `seen` counts
only encounters she could see; the plainer alternative is one `influenced` name for both, which
mixes the off-screen ones into the ratio.

Open for whoever picks it up: whether `nappy-day-3-seen-fire` and `nappy-day-N-pelican-seen` stay
beside the new set (proposed: they stay unchanged) — ask the player; and what "within its catch
distance" means for a lethal row, whose reach ends the day, so a near miss there needs a distance
of its own or counts only through the meter. The new signals are listen-only, as every signal that
exists for `VisitCounter` is. `docs/TELEMETRY.md` lists the new names in the same pull request.
