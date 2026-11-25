# No dog walkers in the escape

The player: "there should be no dog walkers in escape it's not a calm night where people walk
their dogs" (inbox #1733 in spry-ferret).

**Build:** the escape has no dog walker (the pedestrian with a dog on a lead, sent ahead of her
down her own sidewalk), whatever build it runs on. **This item waits for calm-hare (the event
director ignores the escape's settings):** the director sends the dog walkers on main, and the fix
is that entry's, which makes the escape's day spec say what the director may send. This item is
done when the escape city sends no dog walker on a direct boot and from a run, which calm-hare's
test holds, and the entry's other readings below are corrected.

**Context, two bags:** every event is drawn from a bag, and there are two. The dawn's bag places
the escape's mix on its streets before she sets off: `DaySpec._place_the_escape_city()` holds
military convoys, finale explosions, abductions, roadblocks and empty marbles, and no dog walker.
The director's route bag is drawn from as she walks, and its marbles land ahead of her on her
route. `EventDirector.start_day()` fills it on every walk, the escape's city walk included
(`EventsAhead.start_a_given_walk()`), from `_route_rows_on()`: the catalogue's recurring rows
the day makes available that are `AHEAD_OF_PLAYER`, `TOWARD_PLAYER` or sent ahead of her, in
proportion to their weight, and `dog_walker` is one of them.

**What main does, by reading the code (an earlier reading, corrected below):** the route bag is
filled on the escape and drawn from only for a slot the dawn owes the walk. `EventDirector.due()` returns nothing while nothing is
owed (`_owed` and `_sent_waiting` empty), and `_owed` is filled in `start_day()` from the
walk's plans that come after her. The escape's dawn owes none by that reading:
`DawnContext.catalogue_rows()` returns nothing on a walk with a bag of its own
(`DaySpec.walk_bag()`), so its marbles are all placed before she sets off, and the escape
owes no return. That reading is wrong on the direct boot (an Opus audit of main, read from the code and not
measured, calm-hare): `EventsAhead.start_a_given_walk()` hands `EventDirector.start_day()` the
run's day number and not the walk's spec, and under `--start-escape` or `?escape=1` the run is on
day 1, so `_rig_day_one()` rigs two dog walkers among her first three director marbles; from a
run (day 14) the director sends the charging dog one escape in four instead. The dog walker the
player met is explained by the direct boot; which build they played is still the board question
escape-build-played.

**Proposed, not asked for:** if main shows a dog walker in the escape, the escape gets a route
bag of its own, or an empty one, set by its day spec the way the dawn's bag is. The plainer
option: nothing to change if main already shows none, and the entry closes with that reading.
Nothing replaces the dog walker either way; how full the escape is belongs to lilac-marten (a
fuller escape).
