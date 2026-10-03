priority: later

# breezy-hawk — The neighbor walks to work and goes in at the station · filed 2026-10-03

> "the neighbor should actually follow a route that goes to work and disappear at its entrance. he
> should not unload so you might cross paths with him at any point of the route."

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 12 (note #449). **The neighbor walks a route to the power station and goes in at its
door**, never unloaded on the way, so she can meet him anywhere along it. Today
`ResistanceHappenings._send_the_neighbor_to_work()` (`src/resistance/happenings.gd`) walks him along
her own street "until the street runs out or something closes it, then off the ordinary way";
NARRATIVE.md has him work at the power station; `CityMap.power_station_door` exists.

**The player's own two questions, open:** "should there always be a path that goes to the power
plant so the neighbor can follow it without disruption?" — a guaranteed path is a city-skill
guarantee (closures are checked before they are accepted), and from day 9 the region walls close, so
the route may cross a checkpoint door where walkers are held; and "what happens on the day where he
goes home?" — day 10 spawns him 55 s of walk from her door (`NEIGHBOR_WALK_HOME_SECONDS`).
