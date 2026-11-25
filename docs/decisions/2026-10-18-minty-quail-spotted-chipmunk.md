# minty-quail — Row 3b's day spec keeps its fields private · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): fields are not API
(inbox #1173 in gray-dolphin; **designing-classes**). The day spec's last public fields were read by the suites alone once
the dawn and the event manager asked its methods. This pull request (#1587) is the row's "the day spec's fields go
private", from the Opus design of row 3b (kept in the orchestrator's design folder), built by a Sonnet agent.

**What was built.** `DaySpec`'s `number`, `holds_the_home_streets`, `owes_a_return` and `poster_pursuits` are private;
the suites and rigs ask `day_number()`, `keeps_the_home_streets_clear()`, `owes_her_a_return()` and
`sends_a_pursuer_for_a_torn_poster()`, and the two suites that set a field on a bare spec build the spec the game builds
(`for_day()`, `for_section()`): the dawn's context suite builds its two specs that way, and the finale rig holds that a day's
spec owes its return leg on day 13's spec, beside its check that the escape city's owes none. Their
four `[kept]` lines leave `tools/test_only_members.txt`; the doc comments that named the fields name the methods.
Nothing a player sees or the run log records changes.

**The item.** Row 3b stays open until its last pull request; `field-reads.md` no longer lists the day spec among the
classes with fields read from outside.
