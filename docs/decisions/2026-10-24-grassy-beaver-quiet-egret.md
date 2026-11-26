# grassy-beaver — The thought bubbles: four hints built, four not yet · 2026-11-26

What was built of the thought bubbles (the mechanics), against the design in the grassy-beaver
entry, and what is left.

**Built.** A bubble over her holding one picture, no words. `ThoughtBubble` (`src/player/hints/`,
a child of her in the column the exclamation mark stands in) draws the baked frame, the hint's icon and
the arrow turned toward the way to go. `HintWatch` asks one `HintWatcher` per hint each physics
tick, in a list `SimulationBuilder` composes, and puts the first that applies up, one bubble at a
time; a hint that loses is not counted. `HintLedger` (`src/run/`, a registered `RunSubState`, saved
under `hints`) counts shows, photographed at dawn and given back with a lost attempt, so a retry is
taught again. `Tuning.HINT_SHOWS_PER_LESSON` is the count. A show is a `cue` line in the run log.
Four hints: back to the tutorial route (every time; off the route for 0.6 s; until she is back on
it or in the park; points at the nearest route tile), the zebra crossing (she is on a carriageway
tile; points at the nearest crossing within ten tiles), walk wide of the noise (a source ahead of her
within eight tiles whose `caret_strength()` is not zero), and the way to the park (day 1's start and
each junction the route turns at). The route watchers ask `DayStreets.tutorial_route()` each tick,
because the streets are grown at dawn after the simulation stands.

**Picks, each open to the player's overturn.** Three shows per lesson. A lost attempt gives its shows
back. The simple icon set is the one drawn (`HintKind.ICON_SET_SUFFIX`, one line, for the board
question bubble-set). The exclamation mark wins the column and the bubble waits without being
counted. The design's order is kept for the four built: back to the route, zebra, walk wide, the way
to the park.

**Not built, still the item's.** The bubbles for crossing the street (a body closes her sidewalk and
the far one is open), turning back at a seal or closure, a chalk mark coming into view and a
checkpoint hut she may walk through. Each needs a watcher handed what its question reads (the day's
bodies, the closures, the resistance's mark, the huts), none of which the simulation builder holds;
the ledger, the pictures, the bubble and the watch take them without change. The walk-wide bubble
has no suite of its own and no capture.
