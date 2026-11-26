# grassy-beaver — The thought bubbles: all eight built · 2026-11-26

What was built of the thought bubbles (the mechanics), against the design in the grassy-beaver
entry, with the picks that were the builder's own and the review's findings. The entry's last item
is done, so its queue folder is gone.

**The words.** The player: "thought bubbles -- I really like that idea for immediate feedback
especially since it doesn't need reading", then "we should make it so it only shows a few times for
each new lesson", and "it will become useful eg to also show that guard huts can be walked through"
(curly-moose #819). The lessons the player listed for day one included "turn around at a dead end"
and "cross the street when one sidewalk is blocked" (curly-moose #819); the dead end is day 2's.
The chalk mark: "also a thought bubble should hint on going into the alley to get the mark"
(minty-dolphin #868) and "when the mark becomes visible to the player for the first time it causes
a thought bubble" (gentle-owl #1234).

**Built.** A bubble over her holding one picture, no words. `ThoughtBubble` (`src/player/hints/`, a
child of her in the column the exclamation mark stands in) draws the baked frame, the hint's icon
and the arrow turned toward the way to go, through the scenery drawer the builder hands it.
`HintWatch` asks one `HintWatcher` per hint each physics tick, in a list `SimulationBuilder`
composes, owns its bubble (injected through `setup`, freed with the watch) and puts the first that
applies up, one bubble at a time. `HintLedger` (`src/run/`, a registered `RunSubState`, saved under
`hints`) counts shows, photographed at dawn and given back with a lost attempt, so a retry is taught
again. `Tuning.HINT_SHOWS_PER_LESSON` is the count. A show is a `cue` line in the run log.

Eight hints, in the order they win in: back to the tutorial route (every time; off the route for
0.6 s; until she is back on it or in the park; points at the nearest route tile), the zebra crossing
(she is on a carriageway tile; points at the nearest crossing within ten tiles), turn back (she
nears a seal or closure that leaves no sidewalk on along her heading, `CityMap.is_barred_at()`),
cross the street (a body closes her sidewalk ahead and the far one is open,
`EventManager.has_a_body_on()`; points at the nearest crossing), walk wide of the noise (a source
ahead of her within eight tiles whose `caret_strength()` is not zero), the way to the park (day 1's
start and each junction the route turns at, read from `TutorialRoute.junctions()` through
`RouteWaypoints`), the chalk mark (today's mark first comes into her view,
`ResistanceDirector.mark_on_offer()`) and a checkpoint hut she may walk through (it first comes
into her view, `EventManager.doors_in_sight()`, `EventInstance.inspects_her()`). `NearestCrossing`
is the zebra search the two crossing hints share, cached per tile.

**Per walk.** The streets are grown at dawn after the simulation stands, so no watcher reads
`DayStreets`: `DayDirector._start_the_hints()`, after the city is dressed, calls
`HintWatch.begin_walk()` with the route or null, through `DayWorld.use_hints()` and
`WorldSimulation.hints()`, and each watcher arms itself again for the walk. The chalk watcher is
handed the day's mark (`SimulationBuilder.use_the_mark()`, bound in `main`).

**Picks, each open to the player's overturn.** Three shows per lesson. A lost attempt gives its shows
back. The simple icon set is the one drawn (`HintKind.ICON_SET_SUFFIX`, one line, for the board
question bubble-set). The exclamation mark wins the column and the bubble waits without being
counted. The order above is the design's, with turn back and cross the street before walk wide and
the chalk mark and the hut after the way to the park. A higher hint replaces a lower bubble that is
up, rather than waiting its turn, so the zebra bubble takes the place of the way to the park the
moment she steps into the road. *Proposed, not asked for:* the 0.6 s wait before the route hint, and
the route bubble staying up while she is off the route.

**The review's findings.** The first pass built four hints and left four, and the walk-wide bubble
had no suite and no capture; the watchers read `DayStreets` each tick and the watch held the bubble
it did not own. Fixed by building the four watchers, the per-walk hand-off, the watch owning its
bubble (`use_player()` idempotent), the priority replacement, a walk-wide test against the exact
amber caret answer, and the way to the park reading the junction's box. The evidence of all eight in
play is `docs/evidence/grassy-beaver-thought-bubbles-2026-11-26/`.
