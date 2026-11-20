# minty-quail — Row 3a's dawn asks the day spec, the city map and the closure through methods · 2026-11-20

**What was asked.** Row 3a of minty-quail's `event-interface.md` (the dawn and the walk's ground ask rows and plans):
fields are not API (inbox #1173 in gray-dolphin; **designing-classes**), and the dawn read the day spec, the city map and
a road closure field by field. This pull request (#1583) is the row's "the dawn asks the spec, the map and the closure",
from the Opus design of row 3a (kept in the orchestrator's design folder), built by a Sonnet agent.

**What was built.** The day planner, the dawn's context, the calm kept clean, the mast sites, the calm areas, the dawn's
ambient, the scheduler's `blocked_by()` and the row's ground ask the methods the spec, the map and the closure already
answer. `DaySpec` gains `keeps_her_walk_open()`, `notices_one_at_a_time()` and `keeps_the_unused_calm_clean()`; the
three yes-or-no fields behind them, the day's `world` and `closes_streets` go private, since nothing outside the spec
reads them any more. `RoadClosure.segment`
and `CityMap.square_rects` are private; the suites ask `street_key()`, `mouth_rects()` and `cause_centre()`, and the one
that needed a street's whole rect takes the merge of its two mouth rects, which is that rect by construction. The seven
map fields only the city suites still read take `[kept]` lines. `tools/field_reads.txt` loses nineteen lines; the
placement probe prints the same on the base and the branch; nothing a player sees or the run log records changes.

**Open to overturn (the builder's, where the design was silent or differed):** no `wall_end_at_a()`, since
`CityMap.wall_stands_at_a()` already answers it; the five spec fields made private where the design left them public;
`RoadClosure.segment` made private rather than kept.

**The item.** Row 3a stays open until its last pull request; `field-reads.md`'s city and day-spec paragraphs say what is
left, and `docs/EVENTS.md` and `docs/CITY.md` name the spec's questions.
