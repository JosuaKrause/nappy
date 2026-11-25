# No dog walkers in the escape

The player: "there should be no dog walkers in escape it's not a calm night where people walk
their dogs" (inbox #1733 in spry-ferret).

**Build:** no dog walker (the pedestrian with a dog on a lead the director sends ahead of her) is
met in the escape's city.

**What the code does today:** the escape city's bag (`DaySpec._place_the_escape_city()`) holds
military convoys, finale explosions, abductions, roadblocks and empty marbles, and no dog walker. So
the dog walker the player met comes from outside that bag. The likely path is the director's route
bag: `EventDirector._route_rows_on()` collects every recurring row the day makes available, and
`dog_walker` is one of the rows sent ahead of her (`EventDef.is_sent_ahead()`). Whether the
escape's walk runs that director, and which row of it the player saw, is for the builder to check
before changing anything.

**Proposed, not asked for:** nothing replaces the dog walker; the escape's bag is the player's own
order (trucks, explosions, vans, barriers, then empty), and how full the escape is belongs to
lilac-marten (a fuller escape). A replacement obstacle would be the filer's idea, and a reading of
the player's "the only actual obstacle showing up" rather than part of the ask.
