priority: now

# spry-llama — The counter counts encounters: seen, influenced, and bouts of running · filed 2026-10-04

[misty-newt](../../playtests/2026-10-04-misty-newt.md) files inbox #574, said in a conversation
about the page's GoatCounter events (`VisitCounter`, the list in `docs/TELEMETRY.md`, "The page
counts visits"). The band is `now` from the player's "yeah we can start it for the next patch."

The player opened it:

> would it be overkill to have telemetry for being influenced by an event? just a binary yes if the influence of the event reached a certain threshold. I want to avoid creating too many distinct event but it should be of the form day_x_influenced_by_y

Told a lost day already names its main cause, and that the new events would add who else
contributed:

> I'm not talking about loss I'm talking about whether an event had a meaningful encounter with the event also let's add another set with whether it was (fully; or reasonably) visible on screen (just a part or too far off the edge doesn't count)

What it is for:

> I want to establish two things -- how frequent do certain events actually appear and are players avoiding them or ignoring them?

Told one event per event type per day would count the days an event appeared, not how often:

> don't send only once per day

> I can have three interactions with a yeller -- as long as they're a bit apart from each other those are distinct interactions -- if it's a different yeller it's definitely a distinct interaction

On the gap between two interactions with one instance, whether `seen` follows the same rule, and
whether ordinary walkers and cars stay out:

> I would define the gap as left the screen and encountered again at a later time (eg 5s). this should also apply to seen. we can ignore regular walkers and cars unless there is a good way to measure them. mostly I'm interested in the ratio of interacted/seen

On her own running, which the assistant had proposed leaving out:

> we can count the number of running excluding gaps smaller than 10s

**Asked for:**

- **An encounter** is one event instance coming onto the screen. It ends when the instance leaves
  the screen, and the same instance counts again only when it is "encountered again at a later
  time (eg 5s)". A different instance is always a new encounter ("if it's a different yeller it's
  definitely a distinct interaction"). Not once per day ("don't send only once per day").
- **A seen event per encounter**, when the instance is "(fully; or reasonably) visible on screen
  (just a part or too far off the edge doesn't count)"; the gap rule "should also apply to seen".
- **An influenced event per encounter**: a "meaningful encounter", the influence of the event
  having "reached a certain threshold", "a binary yes", in the note's own form
  `day_x_influenced_by_y`.
- **The reading is influenced ÷ seen per event type** ("mostly I'm interested in the ratio of
  interacted/seen"), to answer how often each event actually appears and whether players avoid it
  or ignore it.
- **Ordinary walkers and cars are left out**, "unless there is a good way to measure them".
- **A count of her running**, "excluding gaps smaller than 10s": a restart less than 10 s after she
  stopped is the same run.

The player's only word after the assistant's last read-back was "yeah we can start it for the next
patch.", an answer to when to file it; nothing below was accepted beyond that.

**Proposed, not asked for:**

- **The names** are `nappy-day-N-seen-<event>`, `nappy-day-N-influenced-<event>` and
  `nappy-day-N-ran`, hyphenated like every other GoatCounter event rather than the note's
  `day_x_influenced_by_y`, and the reading is printed by day.
- **`nappy-day-N-ran` is sent when the bout begins**, whether or not the run excites the baby; the
  alternative is sending it when the bout ends, once its 10 s gap has passed.
- **What counts as an event** is the catalogue's rows, and the pelican as `pelican` rather than its
  row's `cyclist`, the name it already has on the counter. The player was asked whether the
  pelican is included and did not answer; it is open for whoever picks the entry up.
- "Properly on screen" is **at least about 80% of what is drawn for the instance inside the view**;
  a sliver at the edge, or only its halo or warning badge, does not count. The plainer alternative
  is the point test `EventManager._is_on_screen()` already makes (below).
- **A meaningful encounter** is at least **10% of a full meter** landed on her by that instance
  within the encounter, for a row that excites; for a row that does not, coming within its catch
  distance or being chased by it. The assistant offered (a) excitement only and (b) excitement or
  it acted on her, picking (b); the player did not choose between them, and went on from a
  read-back that used (b) without (b)'s third case, a blocker that sat on her planned path and
  that she walked around. That case stays out unless the player asks for it.
- An encounter **begins when any of the instance comes into the view and ends when all of it has
  left**; coming back less than about 5 s after leaving continues the same encounter, so neither
  event is sent again.
- **An influence from off screen** (influenced, never seen in that encounter) is a reading of its
  own, so the ratio is not mixed with it.
- `tools/goatcounter.sh` prints the ratio.
- **The existing `nappy-day-3-seen-fire` and `nappy-day-N-pelican-seen` stay as they are** beside
  the new set. The player did not answer this question; it is open for whoever picks the entry up
  (the alternative is dropping both, since `seen-burning-building` and `seen-pelican` would carry
  the same moment under the new rule).

**What exists.** `EventManager._is_on_screen()` tests one point, the instance's position, against
the view's half extent (`Tuning.VIEW_HALF_EXTENT`), not how much of its drawing is in view; the
fire's `seen-fire` (`EventManager._summon_what_has_been_sighted()`, once per fire) and the
pelican's `pelican-seen` (`EventManager._report_the_pelicans_in_view()`, once per pelican) use it.
`EventInstance.accumulate_landed()` is handed each share an instance lands on her meter, stamped
on its own clock, but keeps only the shares inside the halo's 5 s window (`ExcitementHalo.WINDOW`,
pruned on every write and read), which is what the crying-loss cause and the halos read; a total
over a whole encounter, which can last longer, needs a running sum of its own beside it.
`EventBus.pursuit_began` fires when a pursuer starts chasing her. `Stroller.run_excess_ratio()` is
above 0 whenever she moves faster than walking pace, which is how the run log and `EventManager`
tell running already. Every name `VisitCounter` sends is listed in `docs/TELEMETRY.md`, which the
work updates.
