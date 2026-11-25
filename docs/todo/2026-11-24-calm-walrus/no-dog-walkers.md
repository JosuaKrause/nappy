# No dog walkers in the escape

The player: "there should be no dog walkers in escape it's not a calm night where people walk
their dogs" (inbox #1733 in spry-ferret).

**Build:** the escape has no dog walker (the pedestrian with a dog on a lead, sent ahead of her
down her own sidewalk), whatever build it runs on. Checked on main and on the build the player
played: sandy-goose (do the escape city's rows show up on her way) and the board question
escape-build-played (which build the player played) find where the dog walker came from. The
cause is not asserted here.

**Context, two bags:** every event is drawn from a bag, and there are two. The dawn's bag places
the escape's mix on its streets before she sets off: `DaySpec._place_the_escape_city()` holds
military convoys, finale explosions, abductions, roadblocks and empty marbles, and no dog walker.
The director's route bag is drawn from as she walks, and its marbles land ahead of her on her
route. `EventDirector.start_day()` fills it on every walk, the escape's city walk included
(`EventsAhead.start_a_given_walk()`), from `_route_rows_on()`: the catalogue's recurring rows
the day makes available that are `AHEAD_OF_PLAYER`, `TOWARD_PLAYER` or sent ahead of her, in
proportion to their weight, and `dog_walker` is one of them.

**What main does, by reading the code:** the route bag is filled on the escape and drawn from
only for a slot the dawn owes the walk. `EventDirector.due()` returns nothing while nothing is
owed (`_owed` and `_sent_waiting` empty), and `_owed` is filled in `start_day()` from the
walk's plans that come after her. The escape's dawn owes none by that reading:
`DawnContext.catalogue_rows()` returns nothing on a walk with a bag of its own
(`DaySpec.walk_bag()`), so its marbles are all placed before she sets off, and the escape
owes no return. So main's escape should send no dog walker, and the one the player met more
likely came from an older build (the orchestrator reads that the site serves v0.29.2). Neither
is measured here.

**Proposed, not asked for:** if main shows a dog walker in the escape, the escape gets a route
bag of its own, or an empty one, set by its day spec the way the dawn's bag is. The plainer
option: nothing to change if main already shows none, and the entry closes with that reading.
Nothing replaces the dog walker either way; how full the escape is belongs to lilac-marten (a
fuller escape).
