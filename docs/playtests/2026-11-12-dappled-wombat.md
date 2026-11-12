# Playtest dappled-wombat — PlanBuilder is an object, handed what it asks

2026-11-12.

## #1392

1. **The note.**

   > static functions rather than an object; -- what do you mean by that?

2. **The player's words.**

   > I don't see the benefit of a static function

3. **Context** (the assistant's):

   Said to the orchestrating Claude Code session on 2026-11-11 about polite-tapir's first scheduler step, `PlanBuilder` (building a plan at a tile moves out of `src/events/event_scheduler.gd` into a class of its own). A Fable planner's brief picked static functions: six functions with no state, called on the class with every input passed each time, so the pull request stays a pure move and what is held once a day is decided later by `DawnContext`. The orchestrator explained the alternative, an object created once and handed what every call shares, and noted that designing-classes says a component is handed what it depends on, never fetching it from a static, while the planned functions call other classes' stateless static functions (`StreetInvalidation.room_around()`, `EventInstance.mover_for()`) that a test cannot swap for a fake. An Opus builder was already building the static version.

4. **Read as:** (the assistant's interpretation, not the player's words)

   `PlanBuilder` is an object, not a class of static functions: it is created with, and handed, what it depends on, and its callers are handed it, so a test can give it fakes (designing-classes, a component is handed what it depends on). The step stops being a pure move of text, but it still changes nothing a day places. The Fable planner revises the design for the object shape (what it is handed, who builds it, how callers get it); the builder builds that. Whether this extends to static functions elsewhere was not said.

5. **The player's words.**

   > the object approach fits exactly into the dependency injection way we should be doing things

6. **Context** (the assistant's):

   Said right after the note above, while the orchestrator was holding the builder and asking the Fable planner to redesign PlanBuilder as an object.

7. **Read as:** (the assistant's interpretation, not the player's words)

   The reason for the object: dependency injection is how the code is built (designing-classes), and an object handed its collaborators is that; static functions that call other classes' statics are not. The planner's revision hands PlanBuilder what it uses rather than keeping static calls where a collaborator can be handed.
