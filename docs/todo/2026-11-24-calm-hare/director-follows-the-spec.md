# The escape's day spec says what the event director may send

The player: "the escape is just like a normal day with some special settings" and "all should be
implemented through the regular game engine's means" (inbox #785 in minty-lemur); "there should be
no dog walkers in escape it's not a calm night where people walk their dogs" (inbox #1733 in
spry-ferret).

**Build, in one line:** the escape's day spec says what the director may send her (nothing, or a
bag of its own), `EventsAhead.start_a_given_walk()` hands that to `EventDirector.start_day()`, and
the day number stops deciding it: the route bag, the day-one rig and the sprinkled charging dog
follow the walk's settings, so the escape city sends no dog walker on day 1 (the direct boot) and
no charging dog on day 14 (from a run), and an ordinary day is unchanged.

**Test:** a suite plans the escape city and runs the director on day 1 and on day 14 and requires
that it sends nothing the spec does not allow, in the way the game reaches it (**writing-tests**).

**The false comments, fixed in the same pull request**, each saying what the code now does:

- `EventsAhead.start_a_given_walk()`: "the director owes nothing — every such placement is
  `MAP`-sited".
- `EventManager.start_day()`: "a walk planned whole before she sets off owes the director nothing".
- `EventManager.step_what_is_ahead()`: "nothing is sited in a world with no director or in a walk
  planned whole" (the code gates on a scene recipe and on whether a director exists only).
- `DevFlags.start_escape()`: "none of an ordinary day's events".
- `DaySpec`'s class comment: what differs for the escape "is written here, as values ... rather
  than asked of a global 'are we in the escape'" (the director's bag, rig and sprinkle are no value
  of the spec yet).
- `docs/EVENTS.md`, "The escape — the walk filled before she sets off": it says the phases that
  place the catalogue's rows find none, which holds of the dawn, and never mentions the director,
  which still runs; the section says what the spec hands it.

**Proposed, not asked for:** that the spec carries the director's setting (the player asked for no
dog walkers and for the regular engine's means, not for this mechanism); whether the escape's
director sends nothing or draws a bag of its own is open, and the plainer option is nothing, since
every danger the escape holds is placed before she sets off. Nothing is asked of the trucks being
placed before she sets off either: the player said of a day's convoy that it should not be drawn at
the beginning (silky-lemur #1460), and has not ruled for the escape, whose bag was prefilled on the
player's allowing a prefill (inbox #785 in minty-lemur).
