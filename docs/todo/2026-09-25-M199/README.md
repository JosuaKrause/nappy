priority: now

## M199 — The roadblock closes its whole street · asked for 2026-09-25, after the release

> "close the street fully"

[PLAYTEST-135](../../playtests/PLAYTEST-135.md), statement 7.

The catalogue roadblock's band is 120px long on a 192px street, centred on a road-lane tile 16px
off the street's middle. That leaves 20px on one side and 52px on the other, and 52px is wider
than the 28px pram, so she can walk round every catalogue roadblock on one sidewalk. The region
wall's roadblocks are not affected: they are three narrower bodies across the street and close it.

**Band `now`.** [tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #930: "yes", to moving it to now.

**A roadblock on a carriageway rides with this entry.** No sidewalk rule sees a catalogue `roadblock` on a carriageway, only the junction rule when it is near one; making the roadblock a true closure of its street settles it. It was a follow-up of M129 (a path through the city never has to cost), which closed in the queue review ([tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #931: "yes", to letting it ride with this entry).
