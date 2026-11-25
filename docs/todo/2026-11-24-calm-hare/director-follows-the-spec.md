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

**The escape's moving army trucks are sent ahead of her.** Asked on the board whether the escape
city's army trucks, like a day's convoy, should be sent ahead of her as she walks and not placed
before she sets off (the board question escape-convoy-at-dawn, whose pick was to keep them placed),
the player: "no, trucks get placed ahead of her if they're on route. are you referring to trucks as
barriers? if so then, sure they're off route blokades" (inbox #1740 in minty-hare). *Read as, the
filer's:* the trucks of the escape's bag (`military_convoy` marbles, the moving army truck) on her
route are sent ahead of her by the director as a day's convoy is (silky-lemur #1460), and the
barriers drawn as trucks that seal the streets off her walk stay placed at dawn as off-route
blockades. That sending ahead is the director's part of this item. **How the escape's bag and the
director share the trucks is for the builder to design** (which of the bag's marbles are the director's
and which the dawn places, and what the director may send beside them), and the design is written in
the record.

**Proposed, not asked for:** that the spec carries the director's setting (the player asked for no
dog walkers and for the regular engine's means, not for this mechanism); whether the escape's
director sends nothing or draws a bag of its own is open, and the plainer option is nothing, since
every danger the escape holds is placed before she sets off. The trucks are settled below.
