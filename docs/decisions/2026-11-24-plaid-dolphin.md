# plaid-dolphin — The dead-code survey is a committed tool · 2026-11-24 · not from an entry

The dead-code survey had been run by hand about five times from throwaway scripts (records minty-quail-sandy-pelican, -crisp-quail, -crisp-rabbit, -misty-ferret, -jolly-hawk), so it is now `tools/dead_code.py` (a manual sequence done a second time becomes a script, woolly-finch 23).

**What it lists** (six sections, `--section` picks): definitions whose name is a word nowhere else (comments blanked, strings kept, so a `call("name")` reaches), members no typed receiver reaches (public through `check_test_only_members.py`'s receiver typing, private through its own definition pattern), enum values named once or only ever a table key, match arm, membership test or equality test, signals never emitted or never referred to, files no other file names, and tool definitions nothing but tests use. Every row says where it was looked for. It lists and never deletes.

**Run on main** it lists `notice_run()`, `FieldSpec.falling_off()`, `InteriorTile.Kind.ENTRANCE_BARRICADE`, the eight `InteriorTile.Kind` values nothing paints (HALLWAY_FLOOR, HALLWAY_FLOOR_EDGE_E/W, BASEMENT_FLOOR_EDGE_E/W, STAIR_FLIGHT_E/W, LANDING), of which the hand sweep named six and missed the two basement edges (a membership or equality test counts as a consumer, not a producer, so the stair flights are listed), and the three roof preview scenes. A full run takes about a minute, mostly the typing.

**Rejected:** counting a name's words alone for members (a namesake in another class hides a dead member); treating a test-only member as dead (writing-tests rules on those); a verdict in place of a candidate, since a call on another instance of the own class and a name reached by string show as dead or unsure.
