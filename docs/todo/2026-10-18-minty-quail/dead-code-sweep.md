# Code nothing reaches, and code for features the game no longer has, is deleted

**The ask.** "remove dead code or code needed for features that don't exist anymore. it adds to the
cost of maintaining the code base and confuses you. if we want a feature back we can just implement
it fresh which also guarantees that it adheres to the new design principles" (inbox #1180 in gray-dolphin).

**Read as:** code nothing reaches, and code that only serves a feature the game no longer has, is
deleted rather than kept; a feature wanted back is built fresh under the current design. The rule
is designing-classes'. This item is the sweep, across `src/` and `tools/`, one module per pull
request.

*Proposed, not asked for:* the method. Start from `tools/check_test_only_members.py`'s no-reader group
(members nothing under `src/` reads) and the members only their own file uses, then the catalogue
rows and the branches no catalogue row reaches. A name in a comment is not a use: the survey is
run with comments stripped, since a first survey that counted them missed four members
(minty-quail-misty-ferret). Each deletion says in its pull request what reached
the code last, or that nothing ever did.

**Where the rest is:** the survey (`check_test_only_members.py`, a scan for members named nowhere in
`src/`, `tests/`, `tools/` or `scenes/`, and the check's receiver typing for a public member no
file reaches whose name another class shares) finds these, by module; each is read before it goes,
and a member only tests reach stays where its test is the only check of behaviour the game uses.

- `src/crowd/`: `WalkerDoorHold.waiting()`, how many walkers queue behind whoever is inside a
  checkpoint hut, which nothing has called since the hold at a door came in (M110).
- `src/dev/`: `DevFlags.RIG_KILL_GRACE_SECONDS` and `RIG_MOVIE_SLOWDOWN`, which no script reads: the
  shell helper (`tools/lib_dev_flags.sh`) takes both values from the `RIG_QUIT_SECONDS` marker block
  in `dev_flags.gd`'s doc comment, so the two constants are a second statement of the block's
  `kill_grace` and `movie_slowdown`.
- `src/ui/`: `PauseScreen._hint`, the handle on the pause screen's hint label, which nothing writes;
  its doc says why the label stays empty, and `DaySummary`'s comments point at that doc.
- `src/visuals/`: `AtlasLibrary.MEMBERSHIP_PATH`, the atlas membership file's path, which nothing
  under `src/` reads; the bake (`tools/bake_atlases.gd`) and `tests/test_atlas_library.gd` each
  declare their own.
- `src/game_enums.gd`: `GameEnums.District`, an enum nothing names; `docs/ARCHITECTURE.md` lists it
  among the shared enums a script annotates with.
- `src/events/`, for the events' interface rows that rewrite its files (`event-interface.md`):
  `EventDef.effect()`, which nothing calls (4b); `PendingWarning.left`, which only tests read (the
  `[no reader]` group of `tools/test_only_members.txt`; 3b); `EventHold.stop()`, a hold ended by
  hand "for a rig", which no rig calls (4b, with the hold's part).
- `src/resistance/`: nothing.
- `tests/` and `tools/`, helpers nothing calls: `tests/crowd_rig.gd` `_distance_along`,
  `tests/fake_calm_areas.gd` `set_besides`, `tests/fake_walk_events.gd` `set_calm` and `set_doors`,
  `tests/front_reads.gd` `picture_count` and `lit_windows`, `tests/resistance_reads.gd` `home_reach`,
  `tests/resistance_rig.gd` `_two_nearby_alleys`, `tests/test_day13_guard.gd` `robbery_edge_of`,
  `tests/test_events_fire.gd` `_another_branch`, `tests/test_interior.gd`
  `_walk_distance_to_nearest`, `tests/test_resistance_traps.gd` `_is_really_on_screen`,
  `tests/test_route_rig.gd` `_find_tile`, `tests/test_scene_recipe_runtime.gd` `_log_message`, and
  `tools/cost_table.gd` `TABLE_TITLES`.

The pass after these runs the survey again.
