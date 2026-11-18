# minty-quail — The day's clock, the day's end and the run's flow read through their methods · 2026-11-18

**What it is.** A part of minty-quail's `field-reads.md` conversion: the fields of the day's clock
(`DayController`), the day's end (`DayEnd`, what the day director settled about a day that just
ended) and the run's flow (`RunFlow`, the run's way through its screens), read from outside their
files by `main.gd`, the day director, the run log's observer, the summary screen and the
developer's rigs; thirty-three lines of `tools/field_reads.txt`. An Opus builder designed and
built it. It changes nothing in play.

**What was built.** The day's end is a value built once, `DayEnd.new(result, reason,
elapsed_seconds, exit_reached)` with four marks for what the calendar does next, every fact read
through a getter (methods, since designing-classes keeps properties inside their own class), and
one new question, `ends_a_section()`. The run's flow gains `mode()`, `spec()`, `scene()`,
`opening()` with `set_opening()`, and `plays_an_authored_scene()` in place of the `authored`
property. The day's clock gains `use_the_spec()` and `spec()`, `phase()`, `hard_fail_reason()`,
and `set_invincible()` with `is_invincible()`; where a method already answered (`seconds_left()`,
`seconds_total()`, `loss_reason()`, `exit_taken()`, `is_running()`) its readers use it. Tests
reach state the way the game does (dusk is `tick(seconds_left())`; each screen through the call that
raises it in play), and a shared fake clock (`tests/ended_clock.gd`) serves the director's and the
run log observer's suites. All thirty-three lines are gone from `tools/field_reads.txt`; none was
added and no field is kept public.

**Proposed, not asked for, open to the player:** `finished_day` and `cause` removed from the day's
end, since no game code read them off it and `EventBus.day_ended` carries both; `mode()` and
`phase()` as getters callers compare rather than one question per value; `is_running()` reused for
`main.gd`'s walking-or-carrying-her-home check; one shared fake clock rather than one per suite; the
new names.

**Found outside it:** `tools/typing_census.py --check` reports opt-out lines in
`src/events/event_director.gd` and `event_scheduler.gd` naming warnings they no longer trip; it
predates this change and is left for the events' pass.
