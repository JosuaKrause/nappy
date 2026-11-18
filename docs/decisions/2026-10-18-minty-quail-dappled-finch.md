# minty-quail — The day spec's fields read through its methods outside the events · 2026-11-18

**What it is.** A part of minty-quail's `field-reads.md` conversion: the day spec's (`DaySpec`, what a
day or a section of the escape is) fields read from outside its file outside the events, by
`main.gd`, the run calendar, the run log's session, the seal planner and the developer's rigs;
twenty-one lines of `tools/field_reads.txt`. An Opus builder designed and built it. It changes
nothing in play and moves no balance number.

**What was built.** Private behind methods it already had: `section` (`section_kind()`), `exits`
(`exit_points()`, written through `use_exits()`), `daylight_runs_down` (`runs_the_daylight_down()`).
Private behind new getters keeping the field's name: `title()`, `seal_pictures()`,
`a_win_leads_into()`. Private behind questions with new names: `seals_off_the_main_road()`,
`seals_off_every_other_street()`, `a_loss_undoes_the_attempt()`, `a_win_regains_a_nerve()`,
`is_saved_as_under_way()`. The days' definitions are the spec's own factories (`for_day()`,
`for_section()`), which write the private fields from inside the class, every value unchanged.
`number`, `closes_streets`, `world` and `holds_the_home_streets` stay public for the events' reads;
their readers outside the events ask `day_number()`, `closes_the_streets()` and the new
`world_kind()` and `keeps_the_home_streets_clear()`. The director's section test builds its spec
through `for_section()` as the game does, and fails with the director's section branch deleted. All
twenty-one lines are gone from `tools/field_reads.txt`.

**Proposed, not asked for, open to the player:** `world_kind()` and `keeps_the_home_streets_clear()`
added while their fields stay public for the events, so each fact reads two ways until the events'
pass; `world_kind()` named so because a method cannot share a public field's name; the method
names; no builder.
