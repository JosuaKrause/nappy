# minty-quail — The closures' and their markers' fields read through their methods · 2026-11-18

**What it is.** A part of minty-quail's `field-reads.md` conversion: the fields of the road closure
(`RoadClosure`), the park's fence (`ParkClosure`), the closure marker (`ClosureMarker`) and the park
fence panel (`ParkFenceMarker`), read from outside their files outside the events, by the city
scene, the city map, day 12's park cordon, the telemetry map and the run log's observer. An Opus
builder designed and built it. It changes nothing in play; which closure stands is untouched.

**What was built.** The road closure's `kind` is behind `kind()`; its `segment` stays public for the
day planner's holds alone, and every other reader asks `mouth_rects()` (the city map, the telemetry
map), `covers_tile()` (the park cordon) or `street_key()` with `street_words()` (the run log's
observer, whose closure-sighting line keeps its exact text because `summary_words()` reuses
`street_words()`). The park's fence gains `outward()`, `start_turns_a_corner()` and
`end_turns_a_corner()` in place of `joined_start` and `joined_end`. The closure marker takes its
atlas through `use_atlas()` and its cover through `cover_slice(width, rise)`; the fence panel its
rail through `mount_rail(draws_support, offset)`. Four marker fields the city scene writes and only
`tests/test_spent_park.gd` reads stay public, in the item's group of fields only a test reads.
`tools/field_reads.txt` lost fifteen lines and gained none. `tests/test_atlas_boot.gd`, which finds
every node holding a public `atlas`, would have dropped the closure markers silently; it now counts
the closure pieces and checks the recording library was asked as often, and fails when the city
stops handing the panels their atlas. A stale doc in `park_closure.gd` naming `EventManager.start_day`
as doing the holds names the day planner.

**Proposed, not asked for, open to the player:** `segment` left public with its test reads; the four
test-only marker fields rather than one method setting them all; the method names; `street_words()`
split out of `summary_words()`.
