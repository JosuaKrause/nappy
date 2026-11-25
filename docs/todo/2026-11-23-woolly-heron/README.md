priority: later

# woolly-heron — Test gaps the reviews of the excitement, spacing and event-view work found · filed 2026-11-23

**What this is.** Checks that no suite holds, found by the adversarial reviews of pull requests
1662 and 1663 and not filed. No playtest note is behind it; the band, `later`, is the filer's
proposal. It is an entry of its own, never an item of minty-quail: `writing-tests` holds the suites' shape and the
one-module rule, and a builder takes each item here when the suite it names is next touched,
showing each check failing before it passes, by making the change the item names to the source
and running the suite.

**Items**, one file each:

- `phase-change-clears-excitement-rate.md`: a phase change clears the live event's cached excitement rate.
- `excitement-projects-skip.md`: the work `EventExcitement._projects()` skips.
- `prediction-movement-terms.md`: the prediction suite's source-movement check, position term and axis term.
- `finished-event-look.md`: a finished event's look shows nothing.
- `route-end-spacing.md`: the gap between two route events' ends, and two checks pull request 1662 left weaker.

**A nit for whoever builds these.** The doc comment of `EventInstance.is_past_its_warning()`
(`src/events/simulation/event_instance.gd`) says "a pursuit" asks it; the reader is the scene recipe's pursuing
observation (`src/dev/scene_recipe_runtime.gd`, which asks `event.pursues() and event.is_past_its_warning()`).
The comment is corrected in the first pull request of this entry that touches `event_instance.gd`.
