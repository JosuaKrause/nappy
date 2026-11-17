priority: now

## M199 — The roadblock closes its whole street · asked for 2026-09-25, after the release

> "close the street fully"

[PLAYTEST-135](../../playtests/PLAYTEST-135.md), statement 7.

The catalogue roadblock is the open kind (downy-llama): its band, 128px, stands on the kerb beside
its lane and covers its own sidewalk and the road, leaving the far sidewalk whole, 64px, so she can
walk round every catalogue roadblock on that sidewalk. The closing kind this entry builds closes
all 192px. The region wall's roadblocks are not affected: they are three narrower bodies across
the street and close it.

**M199 builds the closing roadblock, beside downy-llama's open one** (the roadblock covers its own sidewalk and the road, built there with a band that leaves the far sidewalk whole): "there are two kinds of roadblocks. one that is open and one that is closing the street" (inbox #1491).

**Band `now`.** [tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #930: "yes", to moving it to now.

**A roadblock on a carriageway rides with this entry.** On her routes' streets the one-sidewalk rule (`OneSidewalkOpenRule`) asks a catalogue `roadblock` on a carriageway, reading its band where its body stands, and refuses it where a body already closes the far sidewalk; a closing roadblock, whose band takes both sidewalks, would be refused there by the same rule by itself, so it would stand off her routes' streets. It was a follow-up of M129 (a path through the city never has to cost), which closed in the queue review ([tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #931: "yes", to letting it ride with this entry).
