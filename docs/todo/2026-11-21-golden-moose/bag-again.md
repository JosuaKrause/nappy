# A mark's rigged row is a marble of her route's bag again

**What is wrong.** Reading day 6's mark or day 7's mark calls a second entry point,
`rig_the_next_draw()`, which exists in four classes (`ResistanceDirector._rig_her_route_for()`
branches to it, `EventManager` and `EventsAhead` pass it on, `EventDirector` implements it). It
appends the row straight to the list of what her walk lays, and the next look, at most a walking
second later, lays it. No bag is involved. The record says so as departure 2 ("the rigged bag
holds the rows alone ... there is no bag to take the rest from"), while the code's comments and
`docs/EVENTS.md` still describe "the bag in front" as if one existed.

Three things follow from that:

- **It drops a mechanism the player named, twice.** The chained bag is `MarbleBag.rig()`, built
  from the player's own description (inbox #561 in coral-bunny: "create a new marble bag with x
  holdings place the ensured item in the bag fill the remaining x-1 items by *drawing* from the
  currently active bag. x defines how soon we want to get the guaranteed event"). For the man
  shouting the player asked for it by name (olive-koala 2: "a marble bag with 1/3 chance of yeller
  should be put in so the yeller is guaranteed to encounter a yeller in the next three events"),
  set its size (inbox #561: "let's make the other rigged bags smaller, too"; inbox #586 in
  olive-hedgehog: "each olive badger rigged bag should be 2 or 3"), and kept it when asked where
  he lands (inbox #1520 in breezy-magpie: "the bag gets the biased bag in front (via the chained
  bags mechanism) and the next draw (whenever that happens) will guarantee the shouting man").
  Told that keeping him on her street was "not the bag-in-front mechanism you named", the player
  answered "why? you would draw only for the path and only just ahead" (inbox #1549). I read that
  as: keep the bag, and its draw lands on her path just ahead. The orchestrator's own reading on
  the board says the same ("the rigged bag stays"). The bag whose draws are for her path just
  ahead is her route's bag (`EventDirector._route`), the one the player set up for "what the
  player sees on their route" (olive-koala 2). Before #1548 days 6 and 7 rigged exactly that bag;
  #1548 deleted the rig and its two constants (`TASK_CONTACT_WITHIN_THE_NEXT`,
  `VAN_WITHIN_THE_NEXT`, both 2).
- **The record's reason does not hold.** "There is no bag to take the rest from" because "her walk
  lays them": day 11's second mast is also laid by her walk, and it is a marble of her route's bag
  today (`rig_her_route()`, then `_place_on_her_route()` hands it to her walk when its marble
  comes up). A place and a bag marble are not exclusive.
- **A mode became a copy.** Two call chains through four classes do one job, "a task's mark rigs a
  row onto her way". They differ in two per-plan facts kept in side tables of the director
  (`_just_ahead`, and `_placed_from_the_route`, which is now also set for a plan that never came
  from her route's bag, so `is_from_her_route()` answers true for it). They also differ by
  accident: `rig_her_route()` answers nothing on a `--force` day and counts the row among what she
  met today (`_met_today`), `rig_the_next_draw()` does neither; each makes today's copy of the row its own way
  (`_routed()` against `EventCatalogue.heated(...).for_day(...)`).

**The design.** One path for all three tasks, the one day 11 uses. Where the place is laid is a
setting of the rig.

1. `src/resistance/resistance_steps.gd` (data). Restore `TASK_CONTACT_WITHIN_THE_NEXT := 2` and
   `VAN_WITHIN_THE_NEXT := 2` with their doc comments and citations as they stood at
   `4da1e5285^`, each ending with where the place is laid now. Days 6 and 7 set `rigs_within` to
   them. Delete the public field `rigs_the_next_draw`. In its place the step answers a method,
   `lays_its_rigged_row_just_ahead() -> bool`, over a private field set by a configuring call in
   `_build()` (`note_for_a_stranger.lay_the_rigged_row_just_ahead()`, the same for the package).
   A method, because the resistance director reads it from another object and new code reads no
   field across objects.
2. `src/resistance/resistance_director.gd` (simulation). `_rig_her_route_for()` is the function
   as it stood at `4da1e5285^` with one more argument:
   `_events.rig_her_route(ids, task.rigs_within, task.lays_its_rigged_row_just_ahead())`. One
   run-log line, the existing "the next %d on her route are drawn from a rigged bag: ...". The line
   "the next draw on her path stands a rigged ..." goes.
3. `src/events/event_manager.gd`, `src/events/events_ahead.gd` (simulation).
   `rig_her_route(ids, size, just_ahead := false)` passes the setting on; both
   `rig_the_next_draw()` functions are deleted. `EventsAhead.rig_her_route()` already builds the
   day's siting where there is none and does the row's first scans.
4. `src/events/event_director.gd` (simulation).
   `rig_her_route(ids, size, heat, siting, just_ahead := false)` remembers the ids whose place is
   laid just ahead (a set cleared in `start_day()`); `_place_on_her_route(def)` marks the waiting
   plan in `_just_ahead` where the set holds its id. `rig_the_next_draw()` is deleted, and the
   comments of `_placed_from_the_route`, `_on_her_way` and `is_from_her_route()` lose their
   clauses about a row a mark rigs. `site_what_is_on_her_way()` and `WalkSiting` do not change:
   `lay_just_ahead()` stays exactly as built.
5. Day 11's second mast is untouched: rigged within two, laid past the streaming band
   (`lay_ahead()`). The player's answer was asked about the man and the van. Laying the mast just
   ahead too would delete the setting, but it moves where a mast stands with no word asking for
   it; it belongs to freckled-penguin (rethink the masts) if anywhere.

**Tests.** Each holds a rule.

- `tests/test_event_director.gd`: the check that a row a mark rigs is laid by `lay_just_ahead()`
  becomes: a place rigged onto her route with the setting is handed to her walk when its marble is
  drawn, not before, and laid by `lay_just_ahead()`; one rigged without it by `lay_ahead()`; under
  `--force` neither is rigged. With `FakeWalkSiting`, as the suite does today.
- `tests/test_day6_yeller_met.gd`, `tests/test_day7_van.gd`: what they assert stays (he is laid
  out of the camera's view, comes into view, and the man is in the world once she is near, counted
  on every walk). Their walk after the mark must last until his marble is handed out, at most two
  handouts; the versions at `4da1e5285^` walked a day with the rigged route bag and show how.
- `tests/test_resistance_placement_kinds.gd` (its copy of a step), and
  `tests/probes/calm_pelican_day7_van_met.gd` (it finds the rigged row on the director's list).
- New in `tests/test_resistance_steps.gd` or where the steps' settings are held: days 6, 7 and 11
  each rig within two, and only days 6 and 7 lay just ahead.

**What a player sees, and why it may change.** Where he stands does not change. When he is laid
does: with his marble, one of the next two events handed out on her route after the mark (11 to
26 walking seconds apart, 9 to 16 on the way home), instead of at the first look after the mark.
And he takes the place of one of the events the day owes her route instead of coming on top of
them, so the mark makes the day no denser. Both are what the player's words describe ("in the
next three events", "x defines how soon", "the draw doesn't have to happen at the point where she
touches the mark ... the next draw (whenever that happens)"), and both are how it was before
#1548. If the orchestrator reads "the next draw will guarantee" as a bag of one, that is the two
constants set to 1 and nothing else.

**Parity and measurement.** Nothing else moves: `tests/probes/placement_rows.gd` prints the same
before and after, and `tests/probes/walk_rows.gd` is not needed (no beat's siting changes). One
run of `tools/test.sh probes/calm_pelican_day7_van_met.gd`, twelve walks each, is printed beside
the record's table (main 9 and 9 seen; as built 8 seen of 11 laid for the man, 8 of 9 for the
van). It is listed for the end remeasure and not fitted to. If either "seen" falls more than two
walks below the built row, the builder stops and reports instead of tuning.

**Docs made false, rewritten in the same pull request:** `docs/EVENTS.md` (the paragraph "The bag
is a queue of bags", whose sentence "A mark can rig the next draw on her path too" goes; the day 6
and day 7 bullets under "These rigs stand"; item 1 of "Where the code differs from the design"),
`docs/TELEMETRY.md` if it lists the run-log line that goes, `.claude/skills/events/SKILL.md` and
`references/plan-and-excitement.md` (a skill change, flagged to the player), and a decision
record of its own.

**Cost.** One pull request for a Sonnet builder: five files under `src/` with more lines deleted
than added, four suites, one probe, the docs. One probe run of a few minutes.

**What it collides with.** `event_director.gd` and `events_ahead.gd` are files of minty-quail's
row 4b: 4b-9 (a row is written through a draft) rebuilds every copy of a row, and
`EventsAhead.rig_the_next_draw()` holds one such copy that this change deletes; 4b-10 (the row
has no public field) rewrites row reads by script across `src/`. `_rig_her_route_for()` holds the
`EventCatalogue.mast().id` read that 4b converts. So: build it in a gap, not while 4b-9 or 4b-10
is open. Before 4b-9 saves converting a copy that goes; after 4b-10 is as good. It must land
before row 5's dawn group converts the day 6 and day 7 suites, or that group builds on it.
Nothing breaks while it waits.
