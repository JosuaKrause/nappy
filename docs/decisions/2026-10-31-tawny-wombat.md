# tawny-wombat — The army truck and the stairwell masked man are placed after their badge · 2026-11-25

The player, told which dangers got a screen-edge badge while already in the world: "Army convoy
should definitely placed for her not at dawn. Otherwise it might have driven away by then",
"Stair guard could as well be placed when it should appear instead of when entering", "Anyway a
badge shouldn't disappear before the entity is visible", and, answering whether every badge stays up
until its danger is in sight, "The stair guard can become a charger that is triggered by a location
if necessary"; of the badge handler keeping a rule for dangers already in the world, "Don't let
legacy implementations prevent you from establishing a clean design" (minty-dolphin #852).

**The army truck needed no new code.** Checked against main after misty-plover (#1750): every way
`military_convoy` comes into play is already warned first. Day 13's column on the main road comes
through `ResistanceHappenings`, `EventManager.warn_first()` and `spawn_warned()`; a day's convoy
is sent ahead of her by the director (`EventDef.as_sent_ahead()`, warned first, silky-lemur
#1460); the escape's trucks are the director's to send (misty-plover). The only placements of the
row with no warning are the developer's authored scenes (`SceneRecipeRuntime`), which now carry no
badge for it. So the deletion of the badge's measuring fell to this change.

**The stairwell masked man is set off by a place.** He is not in the world from the building's
start. His row carries a set-off distance (`EventDraft.set_off_within()`, 426px, the distance he
used to start his run from; `EventDef.is_set_off_by_a_place()`, `sets_off_within()`), and
`SetOffWatch` (simulation layer, ticked by `EventManager` before the warnings run, handed the
world, the streaming, the warning board and the walk's plans) watches where she is against the foot
of his shaft:

- **She walks into the place** (outside it the tick before, no more than a tile's step away): his
  warning goes up for no time (`EventDef.as_set_off_at_once()`, its badge pointing at the foot of
  the shaft) and he comes on the same tick, already running, so he starts exactly when and where he
  started when he waited at the foot and ran on her coming within 426px of him.
- **She is inside the place already when he may come** (the next of him, or her coming in through
  a door): his badge is up alone for his row's `warned_for()`, `Tuning.WARNING_ALONE_MAX` (1 s),
  first, so he never runs at her with no warning at all (inbox #788 in minty-lemur).
- **He comes only while the foot of the shaft is out of her sight** (`SpawnSiting`'s out-of-sight
  rule over his footprint); until then the warning waits.
- `EventStreaming.set_off()` creates him there with his telegraph spent, told he came under a
  warning (`EventInstance.arrive_from_its_warning()`); `may_set_off()` holds the repeat's wait
  (`FINALE_PURSUER_RESPAWN_SECONDS` after the last one ran out of the top). `EventSetOffRun` runs
  his line from his first tick and says his warning and his charge to the page's counter on it.
- `EventDef.warning_time()` counts a row set off at once from its set-off distance, and
  `EventDef.validate()` holds a row a place sets off to a mobile `MAP` row, warned first, that
  neither waits nor pursues.

**teal-trout-2 changes with it.** He has no standing wait any more: the waiting picture
(`guard_standing_*`) and the hand-raised notice (`guard_alert_*`) that teal-trout-2 put right are
gone (`EventPictures.family_sources()` lists only `guard_lunging_*` for him, so his footprint, and
the out-of-sight test `SetOffWatch` makes over it, is measured over what he draws; the other two
families stay on the atlas for the guardsman), and `_test_masked_man_is_drawn_standing_until_he_goes` in `tests/test_event_views.gd` is
replaced by `_test_masked_man_is_drawn_lunging_from_the_tick_he_comes`. That is the orchestrator's
reading of "a charger that is triggered by a location", open to the player's overturn: the entry
left open whether he still waited once placed.

**Every badge has one path** (`BadgeModel`): a warning put up before its danger exists, announced
for the whole of it, and the thing it created keeping the badge until any of it is in sight
(`EventInstance.was_warned_of()`), or until it is over or gone; one she has seen carries none
again. Nothing in the world is measured. Deleted with the measuring: `_measure_dangers_in_the_world()`,
`BadgeModel.SCREEN_MARGIN`, `CLOSING_SPEED`, `LEAD_TIME`, `SMOOTHING`, `HOLD_WINDOW`,
`Subject.charging`, `EventInstance.has_charged()` and `notice_within()`, the `margin` of
`VisibleView.sees()` and `EventManager.sees()`, `DangerEdge.world_per_screen_px()`,
`NoticeSpec.runs_within()` and `running_within()`, `EventDef.runs_its_own_line()`, and
`EventNoticeRun`'s masked man line warning. The closing-speed reading frosty-marten (#1745) tuned
goes with it, and so does the question coral-swan asked of it (whether a slow frame brings the
masked man's badge up late), closed in this change with its own record, since nothing is measured
for a frame to delay.

**A charger whose charge begins out of her sight puts its badge up** (`EventInstance._begin_the_charge()`,
`was_warned_of()`), the orchestrator's pick on the board (badge-for-chargers-off-screen), open to
the player: deleting the measuring took away the badge every charger not warned first had when it
closed on her from out of her sight. Its start is its warning, so it takes the one path: the badge
goes up as the charge begins with none of the charger in the camera's view, points at it, and stays
until she can see it. A general rule, asked of every charger at the moment its charge begins and
never keyed on a row; one whose charge began in her sight carries none. `tests/test_events_pursuit.gd`'s
`_test_a_charge_begun_out_of_her_sight_carries_the_badge` holds both halves on the man a vehicle
lets out. How each charger not warned first is warned now:

- **the waiting robber** (`alley_robbery`), **the hunting roadblock's guard** (`roadblock` at the
  heat that hunts) and **the dog that waits past day 3** (`charging_dog`): each notices her only with
  its warning picture inside the camera's view and warns on its clock there; a charge it then
  starts out of her sight, from just outside the view, puts its badge up;
- **day 13's guard set on her in her view** (`task_guard`): his raised hand in her view; the same
  rule if his charge begins out of it;
- **the men a vehicle lets out** (`EventsAhead.let_the_officers_out()`): put down where she can see
  them, hand raised; walked away from out of her sight before the hand comes down, the charge puts
  the badge up;
- **the checkpoint guard who steps out of the hut** (`door_guard`): the hut guard's raised hand
  across the road is his warning, and the same rule holds for his charge.

**Still without a badge:** a chaser whose charge began in her sight, who falls behind out of it (she
runs from the dog) and closes again. That start was in her sight, so it carries none; main badged it
by its closing speed.

**Tests.** The badge cases create their dangers under a warning (`spawn_warned()`, or
`arrive_from_its_warning()` on a stand-in): `tests/test_danger.gd`, `test_danger_edge.gd`,
`test_drawn_view.gd`, `test_atlas_boot.gd`; `FakeEventManager.spawn_warned()` tells its instance
it came under a warning, as the real spawner does. Two cases whose whole subject was the measuring
are deleted: `test_danger`'s `_test_the_badge_measures_the_things_own_speed` and
`test_danger_edge`'s `_test_nothing_in_the_margin_is_raised_a_badge_fresh`. `test_badge_model.gd`
is rewritten for the one path; `tests/test_interior_masked_man.gd` sets him off as the game does,
and `BuildingEvents.masked_man()` puts him in the world for the cases about his line or catch.
Also deleted, each testing only the deleted measuring: `test_visible_view`'s
`_test_the_margin_counts_past_the_edge_and_into_a_corner` (the margin of `VisibleView.sees()`),
`test_event_behaviours`' two cases of the masked man's line warning, `test_event_phase`'s
`Warning.tick` case, and `test_badge_model`'s measuring cases. `tests/test_set_off_watch.gd` is new:
`SetOffWatch` with its world, streaming and board faked, holding the tile-step test that tells a
door entry from a walk (walked in gives the copy set off at once, a jump of more than a tile the
row's own badge time) and that nothing comes while the foot of the shaft is in her sight (no
warning goes up, and one run out with the foot in sight is withdrawn and put up again); each case
fails with its rule removed.

**Probes**, each fixed, none deleted: `m207_warning_lead.gd` (a row not warned first is warned by
sight alone; the suites `test_event_manager.gd` and `test_events_pursuit.gd` walk it),
`escape_stairwell_guard_trigger.gd` (finds him once a place has set him off; `CHARGES_WITHIN` now
sets the set-off distance), and `minty_quail_crowd_yields.gd`, `minty_quail_pursuit_timing.gd`
(their "charging" label reads `EventInstance.is_chasing()`).

**Measured.** `tools/test.sh probes/escape_stairwell_guard_trigger.gd` (seed 4242, five ways onto
the second flight, three paces) prints the same fifteen lines on main (`c051a7de8`) and on this
change, line for line: a walker is caught turning plain left from rows 10 and 11 and down-left from
the landing tile (closest 22.0, 22.5 and 22.7px on a tick against his 23.5px catch), a walker
holding plain left from the landing tile gets through (38.0px), and every runner and walk-then-run
gets through (closest 24.6px, the walk-then-run turning at row 11); from the first floor's door he
comes after his one-second badge, 270 to 294px from her, and she is back through the door 0.8 to
1.1s later. `tests/test_interior_masked_man.gd` holds the same outcomes on the real body, and that
each later man is warned for a second first, his warning going up six seconds after the last runs
out of the top. In play (`docs/evidence/tawny-wombat-stairwell-man-set-off-2026-11-25/`, seed 4242,
the building's own walker), his badge went up at 422px as he came, running, and came down 0.9s later
as he ran into her view, 248px away. `docs/COSTS.md` now prices his pass (8.0 points awake walking straight through his
line, 0.0 at 120px), since he no longer waits for her; the pass was dashed for him before.

**Rejected.** A standing wait kept once he is placed (the entry's other reading: placed, standing,
then running, which would have kept teal-trout-2's stages): it leaves a waiting state the player's
"charger that is triggered by a location" does not ask for, and a man standing at the foot of the
shaft is a danger in the world the badge would have to measure again. A second's badge before he
runs where she walks into the place: the player chose no delay (inbox #788 in minty-lemur), and the
probe over her five ways down onto the flight shows a delay lets a walker reach the door on more of
them.

**Open to the player's overturn:**

- he comes running with no standing wait, which changes teal-trout-2's pictures and their test;
- with her inside his place already when he may come again (or entering it through a door), he
  comes after a one-second badge, keeping the rule that he never runs at her unwarned;
- while the foot of the shaft is in her sight, he does not come;
- his fairness check (`EventDef.warning_time()`) counts the copy set off at once from its 426px
  set-off distance, and the row's own, which a door entry gets, from just out of sight with its
  one-second badge added; coming in through the first floor's door, he is created 270 to 294px from
  her once that badge has run (the probe);
- once she has seen a warned thing, its badge never comes back;
- a charger not warned first gets a badge only where its charge begins out of her sight (the list
  above), and a chaser that falls behind out of her sight and closes again gets none.
