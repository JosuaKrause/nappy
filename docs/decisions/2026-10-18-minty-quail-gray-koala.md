# minty-quail — Streaming keeps its own state per plan: row 3b's last pull request · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): streaming keeps its own
state per plan and tells the plan what happened, and the plan holds no live event, the listed layer break the player's
answer "a" on the board was chosen to avoid (inbox #1278 in olive-ferret, point 3); fields are not API (inbox #1173 in
gray-dolphin; **designing-classes**). This pull request (#1598) is the row's last, "streaming keeps its own state per
plan", from the Opus design of row 3b (kept in the orchestrator's design folder), built by a Sonnet agent; fork F4 is
built on the designer's pick (that a plan has been in the world stays the plan's).

**What was built.** `WhereItStands` (`src/events/where_it_stands.gd`, model) is the plan's handle on its live event,
implemented by the live event's inner `Standing` and handed out by `standing()`. The plan is told
`enter_the_world(where)` and `leave_the_world(save)`; its fields `live`, `kept_live`, `was_live`, `comes_in`,
`wait_began`, `repeat_every`, `repeat_after`, `at_her` and `arrives_aged` and its `instance()` go, and it answers
`has_been_in_the_world()`, `is_kept_in_the_world()`, `comes_again_every()`, `comes_again_after()`,
`comes_where_she_stands()`, `arrives_aged()`, `first_comes_in()` and `streaming_distance_from(at)`. Streaming keeps a
table, `_state: Dictionary[EventPlan, StreamedPlan]` (the live event, its countdown, whether the wait starts from now),
and `EventManager.event_of(plan)` asks it. The spawner, the director and `EventsAhead` ask the plan. `tools/layer_map.py`'s
`EventInstance` exception is deleted; `tools/field_reads.txt` loses fifteen lines. `stream_around()` asks one plan
question per plan (`streaming_distance_from(at)`) and one table lookup, where row 3a left three plan questions, the
owed follow-up of the record minty-quail-cozy-stork; not yet measured. Nothing a player sees changes.

**Open to overturn, the builder's where the design was silent or could not be followed:** streaming still reads the
live event's public `is_finished` and `is_leaving` (the design has it ask `is_gone()` and `is_on_its_way_out()`),
since converting streaming, their last reader outside `event_instance.gd`, would leave fields only the suites read,
which `tools/check_test_only_members.py` fails; the suites' reads are row 4a's. The handle keeps a fifth answer,
`field_reaches()`, which the run log's watch of the events she meets asks every tick
(`TelemetryObserver._watch_met_events()`). The escape
roadblock rig's `close()` stands the plan out of the world and leaves "has been in the world" true, where it reset the
field.

**Row 3b is built.** With the records minty-quail-curly-penguin, -brisk-magpie, -lilac-trout, -pebbly-toad, -tall-yak,
-tall-hawk, -spry-trout, -spotted-chipmunk, -amber-squirrel, -tawny-lynx and -gentle-stork, the event manager's parts
ask through methods. polite-tapir's `standing-layer-breaks.md` loses the
dawn-planning group, its one use gone.
