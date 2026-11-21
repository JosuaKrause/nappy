# The day's plan, the streaming, and the excitement query

Read this before touching `EventScheduler.build_day()`, `UnitDraw`, `EventStreaming`,
`EventManager.stream_around()`, `ExcitementSource`, or anything that emits at the baby.

## The day follows from its seed; only the world near the player is built

Every guarantee is stated over a **day** — one usable park, two distinct routes to two distinct calm
areas, a one-shot that fires once per run, determinism from a seed — and all of them are properties
of the *plan*. `EventScheduler.build_day()` plans the dawn's part and prepares the draw of the
day's locations; each unit of them (a street, a junction box, an alley, a park or a square) draws
as she comes near it (`UnitDraw`, `EventsAhead.draw_what_comes_near()`), after every touching unit
of lower rank, so every unit's draw is the same whatever her path, what drawing every unit at dawn
would give, but for a unit a beat of her walk stands in or beside (below). A unit within the stream
radius of her is drawn before the streaming looks there (`EventManager.stream_around()` and the
manager's tick). What streams is the *instantiation*.

**A beat her walk lays takes a location, in a unit that has not drawn where her way has one, and
that unit draws round it** (`WalkSiting`, `PlacementUnit.rig()`). The unit's room starts without
the location and its draw, and the draws of the units touching it, are judged among the beat
(`UnitDraw`); nothing is drawn round a beat first. **A row a mark rigs** (day 6's man shouting,
day 7's van) is a marble of her route's bag (`EventManager.rig_her_route()`, with `just_ahead`); when
it is handed out her walk lays it as a beat, just ahead of her, straight ahead and out of her view
(`WalkSiting.lay_just_ahead()`), where the ground has drawn (inbox #1520 in breezy-magpie). So a unit a beat stands in or beside draws by her path,
on purpose, as can a unit touching one whose draw that changed, since a unit is judged among the
draws of the touching units drawn before it: a beat is a marble, and a day replayed the same way
draws the same (inbox #1521 in breezy-magpie). **A place the resistance sends her to is asked by
where it stands** (`WayConfirmation`, asked wherever a
contact is stood or moved, `ResistanceDirector._she_can_be_sent_to()`): inside the ground already
drawn round her (the stream radius, and round where she reads a mark as far as its task is looked
for and `Tuning.EVENT_DRAW_AHEAD` beyond) it stands as it is, her own paths reaching it without
coming within `WayConfirmation.CLEAR` of an undrawn unit; beyond that ground, the units along a
way from home and round the place draw first. So what a place is judged against is whole, and
nothing a unit draws later stands inside it. The one exception is day 8's burnt building on a day
none of the sidewalk below its door can be reached: its contact and red arrow stay on the facade
behind the burnt shell, where the run's fire burned, which passes unasked. The
other siting that draws nothing is the fire lit at dusk on a won day, after which nothing draws.
A moment the director sends at her (a cat across her
path, a pursuer; `EventsAhead.place_what_is_owed_ahead()`) is no place: it starts in her view or
just off her screen, inside the stream radius, where every unit has drawn. The red arrow's choice
among several places that answer a task is no place either: it is made again twice a second over
the ground as it has drawn. A unit's draw is judged among the beats laid in it or in a unit
touching it, and among no other plan her walk sites. **A new kind of place made from her walk
takes a location through `WalkSiting`, and a new place the resistance sends her to is asked
`_she_can_be_sent_to()`**, or it is judged against a walk that does not hold that ground's rows
yet.

- **Nothing may be seen to appear.** Both radii are wider than half the viewport diagonal.
- **`EVENT_STREAM_RADIUS` must stay wider than the widest field in the catalogue.** Otherwise
  streaming is a way of dropping events on people. `tests/test_event_manager.gd` asserts it.
- **A spent plan stays spent, and a running one resumes.** Streaming may take a running event away
  and give it back; it may never rewind one that has finished, and the bookkeeping an event does
  once — a scar, a block arc — happens on its first instantiation and never again. `EventPlan.age` and
  `EventPlan.travelled` carry it over, and `EventPlan.behaviours` each behaviour's own state. It
  **resumes** rather than catching up on lost time.

**Do not move a guarantee out of the dawn or a unit's own draw and into the streaming.** If
something has to be true of a day, it has to be decided where the day is: at dawn
(`EventScheduler.build_day()`) or by a unit's own draw (`UnitDraw`), each of which reads what is
fixed before she moves (the seed, the day, the run as the day starts), and a unit's draw besides
the beats her walk laid in it or a touching unit, a row a mark rigged among them, whose place is
her walk's on purpose; never the streaming.

## Excitement is a pure query

Events never push a value at the baby. `Baby` asks the `WorldContext` for the sources at its
position (`excitement_sources_at()`, each paired with what it answers from `contribution_at()`:
`ExcitementSource`, which each instance composes as `excitement`) and sums them itself. This is why
events compose by simple addition, there is no ordering to get wrong, and an event can be tested
without a scene. **Do not add a code path that feeds her excitement meter from outside `Baby`.**
The developer's rigs start her bars where a capture wants them (`Baby.seed_meters()`); nothing in
play calls it.

**Nothing reaches her through a building, and a new source has to ask.** Every source's
`ExcitementSource.contribution_at()` zeroes a positive field when `WorldMap.wall_between()` finds
the line from the source to her a tile deep in a building, or at the middle of a wall only one tile
thick; anything else that ever emits is an `ExcitementSource` and goes through the same question.
The trap is the caret's projection: it translates *her* point rather than moving the source, which
is right for the field and wrong for the wall — a wall stays where it is, so the projection asks it
between the two bodies' own projected places.

A contact **startles the person she walked into** — the jolt is a decaying part of that agent's
own field (`CrowdExcitement`). Anything that wants to "add excitement" should find a body to put it
on rather than a third summand; if there genuinely is no body, that is a design conversation, not a
plumbing one.
