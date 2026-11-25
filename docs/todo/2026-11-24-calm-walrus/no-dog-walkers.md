# No dog walkers in the escape

The player: "there should be no dog walkers in escape it's not a calm night where people walk
their dogs" (inbox #1733 in spry-ferret).

**Build:** the escape's city has no dog walker (the pedestrian with a dog on a lead, sent ahead of
her down her own sidewalk).

**What the code does today:** every event is drawn from a bag, and there are two. The dawn's bag
places the escape's mix on its streets before she sets off: `DaySpec._place_the_escape_city()`
holds military convoys, finale explosions, abductions, roadblocks and empty marbles, and no dog
walker. The director's route bag is drawn from as she walks, and its marbles land ahead of her on
her route. `EventDirector.start_day()` fills it on every walk the same way
(`_fill_the_route_bag()` from `_route_rows_on()`: the catalogue's recurring rows the day makes
available that are `AHEAD_OF_PLAYER`, `TOWARD_PLAYER` or sent ahead of her, in proportion to their
weight), and the escape's city walk starts the director too (`EventsAhead.start_a_given_walk()`,
with the run's last day and no heat given). The escape's day spec names no route bag of its own, so
on the escape that bag holds the ordinary rows, and `dog_walker` (`row.drawn(4.5, 26)`, sent
ahead at once) is among them. That is where the dog walker the player met comes from.

**Build, then:** the escape gets a route bag of its own, or an empty one, set by its day spec the
way the dawn's bag is, so that no ordinary row (the dog walker, a patrol, the loose dog) is sent
ahead of her there unless the day spec names it. Which ordinary rows the escape keeps is for the
builder to show the player; the player asked only about the dog walker.

**Proposed, not asked for:** nothing replaces the dog walker; the escape's dawn bag is the
player's own order (trucks, explosions, vans, barriers, then empty), and how full the escape is
belongs to lilac-marten (a fuller escape). A replacement obstacle would be the filer's idea, and a
reading of the player's "the only actual obstacle showing up" rather than part of the ask.
