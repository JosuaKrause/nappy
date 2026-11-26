extends RefCounted
## The catalogue's own fairness contract: the physical and visual shape every row keeps regardless
## of where the scheduler places it -- the geometry a `spread` body draws at, that it fits the
## ground it stands on (a `SIDEWALK` band or a carriageway tile), that a crash is two cars solid
## inside the street it closes, and that no two rows share a picture or a silhouette a badge could
## draw.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again" -- this half is the
## catalogue's own static contract, checked on the rows as they are: no node, no live event, no
## generated city and no planned day is built. The one map built is a bare `CityMap` with a street
## drawn on it (the roadblock's width). A case that needs a live event is
## `tests/test_event_phase.gd`'s or `tests/test_event_views.gd`'s, how a body stands and lies on its
## street is `tests/test_body_stance.gd`'s, and what a planned day places is
## `tests/test_events_placement.gd`'s.
##
## *(M37, playtest 07 finding 2: "not sure what that person was supposed to be".)* The vocabulary's
## first row is that **the entity itself carries most of it**, and the catalogue had been quietly
## failing it since M5: five category looks -- `PERSON`, `VEHICLE`, `OBJECT`, `ANIMAL`, `FIRE` --
## were drawing sixteen of the twenty-eight visible rows between them.

func run(t: TestRunner) -> void:
	_test_a_protest_stays_something_she_can_be_routed_through(t)
	_test_one_barrier_costs_less_than_the_hold_it_stands_at(t)
	_test_catalogue_is_fair(t)
	_test_every_charger_is_built_from_the_runs_charger_timing(t)
	_test_every_timing_the_flag_accepts_keeps_every_row_fair(t)
	_test_a_one_shot_is_sited_on_her_way(t)
	_test_a_row_is_weighed_only_on_ground_it_stands_on(t)
	_test_every_copy_of_a_row_keeps_its_ground_weights(t)
	_test_a_warning_first_is_owed_a_flat_minimum(t)
	_test_the_loose_dog_and_the_cat_do_not_telegraph(t)
	_test_a_row_says_whether_its_coming_is_announced_and_how_fast(t)
	_test_as_warned_first_keeps_the_pieces_too(t)
	_test_a_row_sent_ahead_of_her_is_sent_as_its_own_copy(t)
	_test_spread_classification_follows_every_look_and_copy(t)
	_test_a_spread_body_fits_the_ground_it_stands_on(t)
	_test_a_kerbed_body_still_pins_the_frontage(t)
	_test_a_roadblock_covers_its_own_sidewalk_and_the_road(t)
	_test_a_closing_roadblock_covers_all_of_its_street(t)
	_test_stationary_vehicles_have_a_side_and_an_end_picture(t)
	_test_a_wide_scene_faces_its_street(t)
	_test_a_crash_is_two_cars_solid_inside_the_street_it_closes(t)
	_test_every_other_row_is_one_body(t)
	_test_no_two_rows_draw_the_same_picture(t)
	_test_every_look_carries_its_own_silhouette(t)
	_test_a_row_drawn_on_a_building_stands_nothing_on_the_sidewalk(t)

## **Every charger is built from the run's charger timing** (`EventCatalogue.use_charger_timing()`,
## what `--chargers` hands the catalogue at boot; minty-dolphin #834): handed another, the catalogue
## builds every row again from it and validates every fairness contract on the way, and each charger
## that waits for her warns for its warning, notices her within its factor of the radius it is
## written with, and keeps as much field past its notice as it had, so she still feels it before it
## notices her. A hunting van's notice for the men it lets out, and the investigating patrol car's
## for its policeman, are drawn at the same factor and never past their own field. Handed back the
## one it had, the catalogue builds the rows as they were.
func _test_every_charger_is_built_from_the_runs_charger_timing(t: TestRunner) -> void:
	var was := EventCatalogue.charger_timing()
	var shipped := _chargers_now()
	var timing := ChargerTiming.of(1.25, 1.2)
	EventCatalogue.use_charger_timing(timing)
	var played := _chargers_now()
	for id: String in shipped:
		var before: Array = shipped[id]
		var after: Array = played[id]
		var waits: bool = before[0]
		var written: float = before[1]
		var notice_before: float = before[2]
		var field_before: float = before[3]
		var warns_after: float = after[4]
		var notice_after: float = after[2]
		var field_after: float = after[3]
		var expected_notice := minf(timing.notice(written), field_after)
		t.check(is_equal_approx(notice_after, expected_notice),
				"%s notices her within %.1fpx, %.1f times its written %.1fpx, never past its field"
				% [id, expected_notice, timing.notice(1.0), written] + " (%.1fpx)" % notice_after)
		if waits:
			t.check(is_equal_approx(warns_after, timing.warning()),
					"%s warns for the timing's %.2fs (%.2fs)" % [id, timing.warning(), warns_after])
			t.check(is_equal_approx(field_after - notice_after, field_before - notice_before),
					"%s keeps %.1fpx of field past its notice (%.1fpx)" % [id,
					field_before - notice_before, field_after - notice_after])
	EventCatalogue.use_charger_timing(was)
	var again := _chargers_now()
	for id: String in shipped:
		t.check(again[id] == shipped[id],
				"%s is built as it was once the timing is handed back" % id)

## **Every timing the flag accepts keeps every row fair**: `--chargers` (`DevFlags`) refuses a
## warning under `Tuning.OFFSCREEN_WARNING_MIN` and a radius factor outside
## `ChargerTiming.LEAST_REACH` to `MOST_REACH`, which promises that every row, each of its heated
## copies, the day-4 dog and the escape's roadblock pass `EventDef.validate()` anywhere inside. The
## corners are walked, at the least warning and at 2s.
func _test_every_timing_the_flag_accepts_keeps_every_row_fair(t: TestRunner) -> void:
	var was := EventCatalogue.charger_timing()
	for warning: float in [Tuning.OFFSCREEN_WARNING_MIN, 2.0]:
		for reach: float in [ChargerTiming.LEAST_REACH, ChargerTiming.MOST_REACH]:
			EventCatalogue.use_charger_timing(ChargerTiming.of(warning, reach))
			var rows: Array[EventDef] = []
			for def in CatalogueRows.every():
				for level: int in EventCatalogue.heat_levels():
					var row := EventCatalogue.heated(def, level)
					if not rows.has(row):
						rows.append(row)
			rows.append(EventCatalogue.by_id("charging_dog").for_day(Tuning.RUN_TAUGHT_DAY + 1))
			rows.append(EventCatalogue.escape_roadblock())
			var unfair: Array[String] = []
			for row in rows:
				if not row.validate():
					unfair.append(row.id())
			t.check(rows.size() > 2 and unfair.is_empty(),
					"at a %.2fs warning and x%.2f every one of %d rows is fair (unfair: %s)"
					% [warning, reach, rows.size(), ", ".join(unfair)])
	EventCatalogue.use_charger_timing(was)

## Each charger's `[waits for her, written notice, notice_within, heard_within, warns_for]` as the
## catalogue builds it now: the three that wait for her, a hunting van that lets its men out once it
## notices her, and an investigating patrol car that lets its policeman out.
static func _chargers_now() -> Dictionary:
	var dog := EventCatalogue.by_id("charging_dog").for_day(Tuning.RUN_TAUGHT_DAY + 1)
	var robber := EventCatalogue.by_id("alley_robbery")
	var guard := EventCatalogue.escape_roadblock()
	var hot := Tuning.RESISTANCE_GOAL
	var raid := EventCatalogue.heated(EventCatalogue.by_id("abduction"), hot)
	var patrol := EventCatalogue.heated(EventCatalogue.by_id("police_patrol"), hot)
	var found := {}
	for row: EventDef in [dog, robber, guard, raid, patrol]:
		# A charger's notice is never cut short, so its written radius is its notice at the factor
		# played now; a vehicle's may stop at its field, and is written as its rung's trigger.
		var radius := row.notice_within() / EventCatalogue.charger_timing().notice(1.0)
		if row == raid:
			radius = EventDef.HEAT_HUNTS_WITHIN
		elif row == patrol:
			radius = EventDef.HEAT_INVESTIGATE_WITHIN
		var warns := row.pursuit().warns_for() if row.pursues() else 0.0
		found[row.id()] = [row.pursues(), radius, row.notice_within(), row.heard_within(), warns]
	return found

## The rows whose picture is drawn on the building they stand against rather than on the sidewalk
## they are sited on: the fire on its facade (`FireLook._draw_fire()`), and the burnt building
## it leaves (`CityFronts.mark_the_burnt_frontage()`).
const _DRAWN_ON_A_BUILDING: Array[String] = ["burning_building", "burnt_shell"]

const _SPREAD_LOOKS: Array[EventDef.Look] = [
	EventDef.Look.ROADWORKS, EventDef.Look.STALL, EventDef.Look.ROADBLOCK,
	EventDef.Look.CLOSING_ROADBLOCK,
	EventDef.Look.BARRICADE, EventDef.Look.BURNT_SHELL, EventDef.Look.CAFE,
	EventDef.Look.PROTEST, EventDef.Look.FIREFIGHT,
	EventDef.Look.FALLEN_TREE, EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN,
	EventDef.Look.SCAFFOLDING, EventDef.Look.COLLAPSED_FRONTAGE,
]

## **Whether a row is a spread is its own data** (`BodySpec.as_a_spread()`), set on exactly the rows
## whose picture is a spread and kept by every copy. `_SPREAD_LOOKS` is the catalogue geometry
## contract's independent expected set; PROTEST and FIREFIGHT are removed here because they stand
## along their street without being drawn as a spread (`BodySpec.along_its_street()`). The
## geometry, phase and finish checks only guard against a future unrelated writer.
func _test_spread_classification_follows_every_look_and_copy(t: TestRunner) -> void:
	var def := EventDraft.new("").build()
	t.check(not def.lies_as_a_spread(), "a default invisible definition has no spread")
	var roadworks := EventDraft.new("")
	roadworks.look(LookSpec.of(EventDef.Look.ROADWORKS))
	def = roadworks.build()
	t.check(not def.lies_as_a_spread(), "drawing a spread's picture does not make a row a spread by itself")

	for source in CatalogueRows.every():
		var expected := _SPREAD_LOOKS.has(source.picture()) \
				and source.picture() != EventDef.Look.PROTEST and source.picture() != EventDef.Look.FIREFIGHT
		t.check(source.lies_as_a_spread() == expected,
				"catalogue row '%s' says it is a spread exactly when its picture is one" % source.id())

	var cafe := EventCatalogue.by_id("cafe_tables")
	var reshaped := cafe.redraft()
	reshaped.body(cafe.body().reshaped(GroundShape.band(22.0)))
	reshaped.field(cafe.field().holding_to(15.0).reaching(90.0))
	def = reshaped.build()
	t.check(def.lies_as_a_spread(),
			"changing body and field geometry leaves a café's spread answer true")

	_test_a_copy_of_a_row_lies_as_the_row_does(t)
	_test_a_solid_body_with_no_shape_is_refused(t)

## **A copy of a row lies as the row does, for every copy the game makes**: a copy shares the row's
## body value (`BodySpec`), so what it is on the ground is the row's own. A row is not a
## `Resource`, so `duplicate(true)` is not written on one and a deep copy that loses the body (a body
## holds a `GroundShape`, a `RefCounted`, which a resource's deep copy cannot store) cannot be
## made of it; the last check, the source scan, holds that no game code deep-copies a resource.
func _test_a_copy_of_a_row_lies_as_the_row_does(t: TestRunner) -> void:
	var construction := EventCatalogue.by_id("construction")
	t.check(construction.lies_as_a_spread(), "construction is a spread, so the copies below have an answer to keep")

	var drafts: Array[EventDef] = []
	for source in CatalogueRows.every():
		drafts.append(source.redraft().build())
		drafts.append(source.as_sent_ahead())
		drafts.append(source.for_day(1))
		drafts.append(source.for_day(Tuning.RESISTANCE_GOAL))
		drafts.append(EventCatalogue.heated(source, Tuning.RESISTANCE_GOAL))
		drafts.append(SealPlanner.sealed_variant(source, true))
		drafts.append(SealPlanner.sealed_variant(source, false))
	var kept := 0
	for copy in drafts:
		if copy.body() == EventCatalogue.by_id(copy.id()).body():
			kept += 1
		else:
			t.check(false, "a copy of '%s' shares its row's body" % copy.id())
	t.check(kept == drafts.size() and kept > 0,
			"every copy the game makes (redrafted, sent ahead (warned first where it is), for a day, heated, sealed) shares its row's body (%d)" % kept)

	var deep_copies: Array[String] = []
	for folder: String in ["res://src/events", "res://src/routes", "res://src/resistance", "res://src/day"]:
		_find_deep_copies(folder, deep_copies)
	t.check(deep_copies.is_empty(),
			"no game code deep-copies a resource (a row's body would be lost): %s" % [deep_copies])

## **A body that says it is solid with no shape is named by the body**: the old "obstructs but its
## shape does not reach as far" check is unwritable now (a solid body's reach is its shape's), and
## this is the one fault of that kind a body can still be written with, because `BodySpec.solid()`
## takes a shape a caller may hand as null. `EventDef.validate()` refuses it on this answer, but
## it reports a fault with an engine error, which fails the run, so the suite asks the body.
func _test_a_solid_body_with_no_shape_is_refused(t: TestRunner) -> void:
	var draft := EventCatalogue.by_id("cafe_tables").redraft()
	draft.look(LookSpec.none())
	var bare := draft.build()
	t.check(bare.validate(), "the row the faulty one is made from is valid")
	t.check(not bare.body().is_solid_with_no_shape(), "and its body does not say it is solid with no shape")
	draft.body(BodySpec.solid(null).walked_round().parked())
	var faulty := draft.build()
	t.check(faulty.body().is_solid_with_no_shape(), "a body built solid with no shape says so, which validate() refuses")

## Appends the files under `folder` that call `duplicate(true)` or `duplicate_deep(`.
func _find_deep_copies(folder: String, into: Array[String]) -> void:
	for file_name in DirAccess.get_files_at(folder):
		if not file_name.ends_with(".gd"):
			continue
		var text := FileAccess.get_file_as_string("%s/%s" % [folder, file_name])
		if text.contains("duplicate(true)") or text.contains("duplicate_deep("):
			into.append("%s/%s" % [folder, file_name])
	for sub in DirAccess.get_directories_at(folder):
		_find_deep_copies("%s/%s" % [folder, sub], into)

## A `SIDEWALK` tile is one lane of a two-lane pavement, `SIDEWALK_WIDTH * TILE_SIZE` (64px) wide
## in total, and it is one piece of walkable ground rather than two lanes a body has to fit inside
## one of. `BodyStance._centred_on_the_pavement_band()` moves a stationary, unpinned
## (`pavement_side == ANY`) body from the lane tile `EventScheduler` chose to the middle of that
## whole band, so this is half of the *band*, not half of a *lane*.
const _SIDEWALK_SPREAD_CLEARANCE := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 0.5
## A `ROAD` or `CROSSING` tile sits much further from a building line: `(SIDEWALK_WIDTH + 0.5) *
## TILE_SIZE`, worst case, because it is one of the carriageway tiles in the middle of the
## corridor rather than at either edge of it. `CityMap.pavement_inward()` answers zero for either,
## by design, so `_centred_on_the_pavement_band()` leaves such a body where the scheduler put it.
const _CARRIAGEWAY_SPREAD_CLEARANCE := (Tuning.SIDEWALK_WIDTH + 0.5) * Tuning.TILE_SIZE
## A row that spans the street stands on the kerb beside its carriageway lane
## (`EventDef.stands_at_its_kerb()`), so its band has one sidewalk's width to the frontage on its
## own side and the road's to the far kerb, the same 64px each way: the widest it may be and leave
## the far sidewalk whole.
const _KERB_SPREAD_CLEARANCE := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE
## A row that stands on the middle of its street (`EventDef.stands_mid_street()`) has the whole
## half street either way: the widest it may be, and it then closes the street.
const _MIDDLE_SPREAD_CLEARANCE := Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5

## **A protest has to stay `FRICTION`, and its intensity sits close enough to the line that this
## is the check rather than a formality.** *(2026-09-20: "also protesters have very little
## excitement?"; "should be a bit more".)* A wide field at a moderate rate loses more of its price
## to the walking decay than a narrow fierce one does, so buying back what the decay took pushes
## `walk_through_cost()` toward `EventScheduler.WALL_WORTH_OF_COST` — and a `WALL` is given zero copies on
## any cell a route runs along (`RowGround._times_for_role()`), which would put a protest off every
## route a day plans rather than on one she can be sent to walk through.
##
## Not "the intensity is 19.5", which would be the catalogue read back to itself: what would tell
## you something is that the row changed role, which is asked of the row's own cost and size
## (`EventScheduler.role_for()`), the role a day's placement gives it.
func _test_a_protest_stays_something_she_can_be_routed_through(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("protest")
	var day := def.own_first_day()
	var role := EventScheduler.role_for(def.for_day(day), day)
	t.check(role == GameEnums.BlockerRole.FRICTION,
			"a protest is placed as friction, so the day may put one on a route she walks (%.1f against "
			% def.walk_through_cost() + "the %.1f that makes a wall; placed as role %d)"
			% [EventScheduler.WALL_WORTH_OF_COST, role])

## **A door's price is the detention, not the field, and that has to stay true of the one source a
## door charges as.** *(2026-09-20: "guard posts should emit less excitement by themselves, too";
## "since there can be other obstacles around".)* Every row whose field counts as one barrier (one-barrier flag) collapses
## to the strongest of them at her position (`EventSources.sources_at()`), so a hut, a
## gate and a wall's roadblocks at one corner charge one rate between them. What that rate has to
## stay under is the **toll the hold itself charges**: a detention is spent standing still, where
## `Baby.EXCITEMENT_DECAY_IDLE` is zero and nothing is earned back, so the field bills for every
## second of it on top of `Tuning.CHAT_EXCITEMENT`. Once the field over one hold outweighs the
## toll, the field is what a door costs and the detention is the decoration — which is the
## arrangement the player met coming out of a gate into three roadblocks and a patrol.
##
## The three detainers are already exempt from "nothing is cheaper to walk through than around" for
## exactly this reason, `_PRICED_BY_THEIR_CAPTURE`; this is the same sentence said about the
## strongest thing standing at the same place, which is the one that actually bills her.
func _test_one_barrier_costs_less_than_the_hold_it_stands_at(t: TestRunner) -> void:
	var barriers := 0
	for def in CatalogueRows.every():
		if not def.counts_as_one_barrier():
			continue
		barriers += 1
		var over_a_hold := def.peak() * EventCatalogue.CHECKPOINT_DETAIN_SECONDS
		t.check(over_a_hold < Tuning.CHAT_EXCITEMENT,
				("one '%s' bills %.1f over a %.0fs hold at its core rate, under the %.1f the hold "
				+ "itself charges") % [def.id(), over_a_hold, EventCatalogue.CHECKPOINT_DETAIN_SECONDS,
				Tuning.CHAT_EXCITEMENT])
	t.check(barriers > 0, "there were barrier structures to ask (%d)" % barriers)

## The contract from docs/EVENTS.md: a player who starts walking away the instant an event
## becomes visible clears its outer radius before it reaches full strength. A violation is
## a bug, not a difficulty setting, so the whole catalogue is checked. "Visible" is the badge for a
## row warned of before it exists, so what is held against the floor is `EventDef.warning_time()`
## rather than the telegraph alone.
func _test_catalogue_is_fair(t: TestRunner) -> void:
	var defs := CatalogueRows.every()
	t.check(not defs.is_empty(), "the catalogue is not empty")
	for def in defs:
		t.check(def.id() != "", "every event has an id")
		t.check(def.validate(), "event '%s' gives the player time to walk clear" % def.id())
		if not def.is_ambient() and (def.telegraphs_its_coming() or not def.comes_down_her_line()):
			t.check(def.warning_time() + 0.001 >= def.minimum_telegraph(),
					"event '%s' warns %.2fs before it can reach her >= minimum %.2fs"
					% [def.id(), def.warning_time(), def.minimum_telegraph()])
		t.check(def.heard_within() > def.core_within(),
				"event '%s' has a falloff band to fade across" % def.id())

	# Ambient events are exempt because they never "appear"; assert that is deliberate.
	var playground := EventCatalogue.by_id("playground")
	t.check(playground.is_ambient(),
			"the playground is ambient, so its zero telegraph is intended")

## **Every row warned of before it exists is owed the same flat minimum, whatever its field and its
## speed, and its badge is up alone for at most a second.** *(PLAYTEST-145: "I don't like that the
## warning is tied to the size of the field or the speed" · "all offscreen events should work like
## that"; busy-quail, inbox #569: "1s warning should be enough -- let's apply that to the others as
## well".)* Asked of every such row — the catalogue's own (`cyclist`, the fire engine,
## the resistance's two pursuers) and the copies `EventSpawner.as_warned()` makes of day 13's column
## and of the day-3 dog — and asked as a relation: widening a non-pursuer's field and speeding it up
## leaves its `minimum_telegraph()` where it was, at `Tuning.OFFSCREEN_WARNING_MIN`. Every one's badge
## alone (`EventDef.warned_for()`) is at most `Tuning.WARNING_ALONE_MAX`, and the column's copy cuts
## the planned convoy's in-world telegraph to it rather than carrying it over.
func _test_a_warning_first_is_owed_a_flat_minimum(t: TestRunner) -> void:
	var warned: Array[EventDef] = []
	for def in CatalogueRows.every():
		if def.warns_before_it_exists():
			warned.append(def)
	var convoy := EventCatalogue.by_id("military_convoy")
	var column := EventSpawner.as_warned(convoy)
	warned.append(column)
	warned.append(EventSpawner.as_warned(EventCatalogue.by_id("charging_dog")))
	var ids: Array[String] = []
	for def in warned:
		ids.append(def.id())
		t.check(def.warned_for() <= Tuning.WARNING_ALONE_MAX + 0.001,
				"'%s' is warned of %.2fs before it exists, at most the %.2fs ceiling"
				% [def.id(), def.warned_for(), Tuning.WARNING_ALONE_MAX])
		t.check(def.validate(), "and '%s' gives what it owes" % def.id())
		if def.pursues():
			continue
		var widening := def.redraft()
		widening.field(def.field().reaching(def.heard_within() * 1.5))
		if def.moves():
			widening.route(_route_at_another_speed(def.route(), def.speed() * 1.5))
		var wider := widening.build()
		t.check(is_equal_approx(def.minimum_telegraph(), Tuning.OFFSCREEN_WARNING_MIN)
				and is_equal_approx(wider.minimum_telegraph(), def.minimum_telegraph()),
				("'%s' is warned first and owed %.2fs, and %.2fs with a field half as wide again "
				% [def.id(), def.minimum_telegraph(), wider.minimum_telegraph()])
				+ "and half as fast again: the flat %.2fs either way" % Tuning.OFFSCREEN_WARNING_MIN)
	for id: String in ["cyclist", "fire_truck", "military_convoy", "charging_dog",
			"robber_giving_chase", "van_guard_giving_chase"]:
		t.check(ids.has(id), "'%s' is among the rows warned first (%s)" % [id, ", ".join(ids)])
	t.check(is_equal_approx(column.telegraphs_for(), Tuning.WARNING_ALONE_MAX)
			and convoy.telegraphs_for() > Tuning.WARNING_ALONE_MAX,
			"the column's badge is cut to the ceiling (%.2fs) and the planned convoy keeps its %.2fs"
			% [column.telegraphs_for(), convoy.telegraphs_for()])

## The route `route` walks at `speed` and is otherwise the same: its kind, its length, whether it
## paces and whether it stops where it arrives.
func _route_at_another_speed(route: RouteSpec, speed: float) -> RouteSpec:
	var other := RouteSpec.at(speed, route.kind()).up_to_tiles(route.tiles())
	if route.paces_a_beat():
		other = other.pacing()
	if route.parks_where_it_arrives():
		other = other.parking_where_it_arrives()
	return other

## **The loose dog and the cat do not telegraph their coming.** *(PLAYTEST-145: "telegraphing is for
## things that go fast *and* are dangerous" · "go fast and towards the player" · "loose dog, cat
## don't need telegraphing"; inbox #598: "the telegraphing rule was about heavy penalty not *only*
## lethal" · "fire truck has heavy penalty".)* A thing telegraphs only if it goes fast, comes toward
## her and carries a heavy penalty — it can end the day or hit her hard. Neither of these two does:
## no screen-edge badge and no warning first; the cat still owes its in-world crouch, while the
## fire engine, which can hit her hard, keeps its badge and its warning first.
func _test_the_loose_dog_and_the_cat_do_not_telegraph(t: TestRunner) -> void:
	for id: String in ["loose_dog", "cat_dash"]:
		var def := EventCatalogue.by_id(id)
		t.check(not def.telegraphs_its_coming() and not def.warns_before_it_exists(),
				"'%s' does not telegraph: no warning first, and so no screen-edge badge" % id)
		t.check(def.validate(), "and '%s' gives what the contract still asks of it" % id)
	# The rows that stand until she walks in keep the contract for their in-world telegraph.
	for id: String in ["cat_dash", "alley_mouse", "pigeon_flock", "police_patrol"]:
		var row := EventCatalogue.by_id(id)
		t.check(not row.telegraphs_its_coming() and row.warning_time() + 0.001 >= row.minimum_telegraph(),
				"'%s' does not telegraph its coming, and its in-world telegraph (%.2fs) still clears "
				% [id, row.warning_time()] + "the contract's %.2fs" % row.minimum_telegraph())
	t.check(EventCatalogue.by_id("loose_dog").comes_down_her_line(),
			"the loose dog still comes down her own sidewalk, created at once just out of sight")
	var truck := EventCatalogue.by_id("fire_truck")
	t.check(truck.telegraphs_its_coming() and truck.warns_before_it_exists(),
			"the fire engine, a heavy penalty, keeps its badge and its warning first")

## **What a row says of its coming** (`EventDef.announces_its_coming()`), the screen-edge badge's
## rule, checked here once: a badge for anything lethal, and otherwise only for what comes faster
## than she walks; nothing for a row that does not telegraph. How fast a row comes
## (`approach_speed()`) is its chase speed for a pursuer, and every row it announces has a
## silhouette for the badge to carry.
func _test_a_row_says_whether_its_coming_is_announced_and_how_fast(t: TestRunner) -> void:
	var walk := Tuning.WALK_SPEED
	var robber := EventCatalogue.by_id("alley_robbery")
	t.check(robber.announces_its_coming(walk) and robber.announces_its_coming(walk * 10.0),
			"a lethal row is announced however fast she walks")
	var truck := EventCatalogue.by_id("fire_truck")
	t.check(not truck.ends_the_day() and truck.announces_its_coming(walk),
			"a fire engine, which does not end the day, is announced: it is faster than her walk")
	t.check(not truck.announces_its_coming(truck.approach_speed()),
			"and not to somebody walking as fast as it comes")
	t.check(not EventCatalogue.by_id("loose_dog").announces_its_coming(walk),
			"a row that does not telegraph its coming is not announced")
	t.check(not EventCatalogue.by_id("dog_walker").announces_its_coming(walk),
			"nor a mover she can outwalk")
	t.close_to(robber.approach_speed(), robber.chase_speed(), "a pursuer comes at its chase speed")
	for row in CatalogueRows.every():
		if row.announces_its_coming(walk):
			t.check(not EventPictures.icon_for(row.picture()).is_empty(),
					"'%s' is announced and has a silhouette for its badge" % row.id())
		if row.ends_the_day():
			t.check(row.lethal_reach() > 0.0, "'%s' ends the day within a reach" % row.id())

## **`as_warned_first()` keeps the row's body pieces, as every other copy of a row does** (`at_heat()`,
## `EventDef.for_day()`, `EventCatalogue.neighbor_heading_home()`, `SealPlanner`'s variants: each
## shares the row's body part) — a copy that lost its pieces would quietly go back to one body
## spanning its whole shape. `car_accident` is the row with more than one piece, so it stands in for
## a multi-part row sent through a warning first; its own telegraph is too short to clear the flat
## floor a warned-first row is held to, so the duplicate's telegraph is widened first.
func _test_as_warned_first_keeps_the_pieces_too(t: TestRunner) -> void:
	var crash := EventCatalogue.by_id("car_accident")
	t.check(crash.body().declared_pieces().size() >= 2,
			"'car_accident' has at least two solid parts (%d), so the copy below cannot pass vacuously"
			% crash.body().declared_pieces().size())
	var widening := crash.redraft()
	widening.warning(WarningSpec.lasting(5.0))
	var widened := widening.build()
	var warned := widened.as_warned_first()
	t.check(warned.validate(), "the widened telegraph clears the flat warned-first floor")
	t.check(warned.body().declared_pieces().size() == crash.body().declared_pieces().size(),
			("as_warned_first() keeps %d solid part(s), the row's own %d"
			% [warned.body().declared_pieces().size(), crash.body().declared_pieces().size()]))

## **The dog walker, the patrol and the convoy are sent ahead of her** (inbox #1460 in silky-lemur), and drawn by no
## unit on any day. The copy the director sends (`EventDef.as_sent_ahead()`) validates: the dog
## walker comes down her line created at once, with no badge, its field short of where it is
## created; the patrol comes down the road created at once; the convoy is warned of first in its
## lane, held to the flat minimum a warning first owes and its badge alone at most the ceiling. A
## row the director does not send is its own copy.
func _test_a_row_sent_ahead_of_her_is_sent_as_its_own_copy(t: TestRunner) -> void:
	for id: String in ["dog_walker", "police_patrol", "military_convoy"]:
		var def := EventCatalogue.by_id(id)
		var drawn := false
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			drawn = drawn or def.is_drawn_by_units(day, "")
		t.check(def.is_sent_ahead() and not drawn,
				"'%s' is sent ahead of her and drawn by no unit on any day" % id)
		var sent := def.as_sent_ahead()
		t.check(sent != def and sent.validate() and sent.is_sent_ahead(),
				"and the copy the director sends of '%s' is its own and gives what it owes" % id)
	var walker := EventCatalogue.by_id("dog_walker").as_sent_ahead()
	t.check(walker.comes_down_her_line() and not walker.warns_before_it_exists()
			and not walker.announces_its_coming(Tuning.WALK_SPEED)
			and walker.heard_within() < SpawnSiting.least_distance(),
			"the dog walker comes down her line created at once, with no badge, outside its own field")
	var patrol := EventCatalogue.by_id("police_patrol").as_sent_ahead()
	t.check(patrol.spawn_mode_on(Tuning.RUN_LENGTH_DAYS) == EventDef.SpawnMode.TOWARD_PLAYER
			and not patrol.comes_down_her_line() and not patrol.warns_before_it_exists(),
			"the patrol comes down the road toward her, created at once")
	var convoy := EventCatalogue.by_id("military_convoy").as_sent_ahead()
	t.check(convoy.is_warned_in_its_lane() and convoy.warns_before_it_exists()
			and is_equal_approx(convoy.minimum_telegraph(), Tuning.OFFSCREEN_WARNING_MIN)
			and convoy.warned_for() <= Tuning.WARNING_ALONE_MAX + 0.001
			and convoy.warning_time() + 0.001 >= convoy.minimum_telegraph(),
			"the convoy is warned of first in its lane, its badge alone %.2fs and "
			% convoy.warned_for() + "owed the flat %.2fs" % Tuning.OFFSCREEN_WARNING_MIN)
	var cafe := EventCatalogue.by_id("cafe_tables")
	t.check(not cafe.is_sent_ahead() and cafe.as_sent_ahead() == cafe and cafe.is_drawn_by_units(1, ""),
			"a row the director does not send is its own copy, and a unit draws it")

## **A body on a pavement has to fit on the pavement — the whole of it, not the lane it happened to
## be planned on.** `_draw_spread` and its cousins draw a body at exactly the width `obstructs_within()`
## says, and `EventInstance.setup()` centres a stationary, unpinned body on the pavement band before
## either the drawing or `EventBody.go_down()`'s collision shape ever reads its position — so the
## width is a promise about where she can walk and the promise is kept against the band a `SIDEWALK`
## placement actually offers, not against whichever of its two lanes the scheduler rolled. `SQUARE`,
## `PARK` and `ALLEY` are wide open and carry no bound here; a tile type with no clearance defined is
## skipped rather than treated as a failure.
##
## **Blind spot, not a hole this test can close:** `barricade` lists no `ground_kinds()` of its
## own — it is a spawn sited wherever `military_convoy` stopped rather than placed by
## `ground_kinds()` — so the loop below never sees it and a future regression on its
## `obstructs_within()` would pass silently. Checked by hand instead: it lands on `ROAD` (its
## spawning row's own placement), and 62px sits inside `_CARRIAGEWAY_SPREAD_CLEARANCE`.
## (`burnt_shell`, the other row with no placement, has no body to fit.)
##
## **The same blind spot covers every seal-only row** (`fallen_tree`, `car_accident`,
## `skip`, `scaffolding`, `burst_water_main`, `moving_van`, `burnt_out_car`,
## `collapsed_frontage`) — none lists a `ground_kinds()` either, since `SealPlanner` sites them
## directly from the street lattice rather than through `EventScheduler`'s tile pool. Their
## clearance is checked in `tests/test_seals.gd` instead, against the street's own 192px width
## rather than a single tile's, which is the ground they actually stand on.
func _test_a_spread_body_fits_the_ground_it_stands_on(t: TestRunner) -> void:
	var checked := 0
	for def in CatalogueRows.every():
		if not _SPREAD_LOOKS.has(def.picture()) or def.ground_kinds().is_empty():
			continue
		var half := maxf(11.0, def.obstructs_within())
		for tile_type in def.ground_kinds():
			var clearance := INF
			if tile_type == GameEnums.TileType.SIDEWALK:
				clearance = _SIDEWALK_SPREAD_CLEARANCE
			elif def.stands_mid_street() and tile_type == GameEnums.TileType.ROAD:
				clearance = _MIDDLE_SPREAD_CLEARANCE
			elif def.stands_at_its_kerb() and tile_type == GameEnums.TileType.ROAD:
				clearance = _KERB_SPREAD_CLEARANCE
			elif tile_type == GameEnums.TileType.ROAD or tile_type == GameEnums.TileType.CROSSING:
				clearance = _CARRIAGEWAY_SPREAD_CLEARANCE
			if clearance == INF:
				continue
			checked += 1
			t.check(half <= clearance,
					"'%s' draws %.0fpx wide, which fits the %.0fpx that a %d-type tile clears"
					% [def.id(), half * 2.0, clearance * 2.0, tile_type])
	t.check(checked >= 6, "and the rule covers the catalogue's spread rows (%d checks)" % checked)

## **The kerb exception must not silently regress.** `delivery_van` and `ice_cream_van` are
## `pavement_side == AT_THE_KERB` on purpose — `EventCatalogue`'s own docstring is "a parked van
## belongs at the kerb" — so `_centred_on_the_pavement_band()` must leave them flush against it
## rather than re-centring them onto the pavement band the way `construction` is (where each stands
## is `tests/test_body_stance.gd`'s). A kerb-parked
## `VEHICLE_BODY` (44px across) still has to leave a gap to the frontage narrower than the pram, or
## the row stops being an obstacle: `docs/EVENTS.md`'s `delivery_van` row reads that placement as
## "a **wall** by physical fit", and the gap is the exact shape of "no line to walk."
func _test_a_kerbed_body_still_pins_the_frontage(t: TestRunner) -> void:
	var kerb_edge := Tuning.TILE_SIZE * 0.5
	var band := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE
	var frontage_gap := (band - kerb_edge) - EventCatalogue.VEHICLE_BODY
	t.check(frontage_gap < Tuning.PLAYER_BODY_RADIUS * 2.0,
			"a %.0fpx VEHICLE_BODY at the kerb leaves %.0fpx to the frontage, narrower than the "
			% [EventCatalogue.VEHICLE_BODY, frontage_gap]
			+ "%.0fpx pram" % (Tuning.PLAYER_BODY_RADIUS * 2.0))

	var barrier := EventCatalogue.by_id("construction")
	# And the payoff, stated as the arithmetic that decides it rather than as a distance: with
	# `construction` centred on the band, no point on the pavement is far enough from it to clear
	# `obstructs_within() + PLAYER_BODY_RADIUS` — the pram cannot pass on either lane, which is what
	# "the only Act I event that is physically in the way" means.
	var half_band := Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE * 0.5
	t.check(barrier.obstructs_within() + Tuning.PLAYER_BODY_RADIUS > half_band,
			"a centred 'construction' (%.0fpx + %.0fpx pram) reaches past either edge of the %.0fpx "
			% [barrier.obstructs_within(), Tuning.PLAYER_BODY_RADIUS, half_band * 2.0]
			+ "band, so it seals the whole pavement rather than one lane of it")

## **A roadblock covers its own sidewalk and the road, and leaves the far sidewalk whole** ("okay
## let's use the one sidewalk has to be open and match the roadblocks size to one sidewalk + road",
## inbox #1465 in spry-plover). On a hand-drawn street of each axis, a roadblock put on either
## carriageway lane is solid from the frontage on its own side to the far kerb and nowhere past it,
## read along the band's own line through where its body stands (`BodyStance.center()`) and
## the shape the row collides as. The map is real because the guarantee is the row's width and
## where the map stands it together: neither alone says where the band ends.
func _test_a_roadblock_covers_its_own_sidewalk_and_the_road(t: TestRunner) -> void:
	var row := EventCatalogue.by_id("roadblock")
	var shape := row.ground_shape()
	var map := CityMap.new()
	var off_the_corridor := Tuning.STREET_WIDTH + 3
	var street := float(Tuning.STREET_WIDTH * Tuning.TILE_SIZE)
	var sidewalk := float(Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE)
	for across_x: bool in [true, false]:
		for offset: int in Tuning.STREET_WIDTH:
			var tile := Vector2i(offset, off_the_corridor) if across_x \
					else Vector2i(off_the_corridor, offset)
			map.set_tile(tile, GameEnums.TileType.ROAD if CityMap.is_road_offset(offset)
					else GameEnums.TileType.SIDEWALK)
		var across := Vector2.RIGHT if across_x else Vector2.DOWN
		for lane: int in [Tuning.SIDEWALK_WIDTH, Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH - 1]:
			var tile := Vector2i(lane, off_the_corridor) if across_x \
					else Vector2i(off_the_corridor, lane)
			var placed := map.tile_to_world(tile)
			var stance := BodyStance.of(map, row, placed, Vector2.RIGHT)
			var stands := stance.center()
			var axis := stance.pieces()[0].axis()
			var own_low := lane * 2 < Tuning.STREET_WIDTH
			var own_edge := 0.0 if own_low else street
			var far_kerb := street - sidewalk if own_low else sidewalk
			var far_edge := street if own_low else 0.0
			var toward_far := 1.0 if own_low else -1.0
			var name := "a roadblock in the lane at %.0fpx across %s street" \
					% [placed.dot(across), "a north-south" if across_x else "an east-west"]
			t.check(_solid_across(shape, stands, axis, placed, across, own_edge + toward_far * 0.5),
					"%s covers its own sidewalk to the frontage" % name)
			t.check(_solid_across(shape, stands, axis, placed, across, far_kerb - toward_far * 0.5),
					"%s covers the road to the far kerb" % name)
			var open := 0.0
			var at_across := far_kerb + toward_far * 0.5
			while (far_edge - at_across) * toward_far > 0.0:
				if not _solid_across(shape, stands, axis, placed, across, at_across):
					open += 1.0
				at_across += toward_far
			t.check(open >= sidewalk,
					"%s leaves the far sidewalk whole: %.0f of its %.0fpx open" % [name, open, sidewalk])

## **The closing roadblock covers all 192px of its street.** On a hand-drawn street of each axis,
## a closing roadblock put on either carriageway lane stands on the street's middle and is solid
## from the frontage on one side to the frontage on the other, both sidewalks included.
func _test_a_closing_roadblock_covers_all_of_its_street(t: TestRunner) -> void:
	var row := EventCatalogue.by_id("closing_roadblock")
	t.check(row != null and row.stands_mid_street()
			and not row.stands_at_its_kerb(), "the catalogue carries a roadblock that closes its street")
	if row == null:
		return
	var shape := row.ground_shape()
	var map := CityMap.new()
	var off_the_corridor := Tuning.STREET_WIDTH + 3
	var street := float(Tuning.STREET_WIDTH * Tuning.TILE_SIZE)
	for across_x: bool in [true, false]:
		for offset: int in Tuning.STREET_WIDTH:
			var tile := Vector2i(offset, off_the_corridor) if across_x \
					else Vector2i(off_the_corridor, offset)
			map.set_tile(tile, GameEnums.TileType.ROAD if CityMap.is_road_offset(offset)
					else GameEnums.TileType.SIDEWALK)
		var across := Vector2.RIGHT if across_x else Vector2.DOWN
		for lane: int in [Tuning.SIDEWALK_WIDTH, Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH - 1]:
			var tile := Vector2i(lane, off_the_corridor) if across_x \
					else Vector2i(off_the_corridor, lane)
			var placed := map.tile_to_world(tile)
			var stance := BodyStance.of(map, row, placed, Vector2.RIGHT)
			var stands := stance.center()
			var axis := stance.pieces()[0].axis()
			var name := "a closing roadblock in the lane at %.0fpx" % placed.dot(across)
			t.check(is_equal_approx(stands.dot(across), street * 0.5),
					"%s stands on the middle of its street (%.0f)" % [name, stands.dot(across)])
			var open := 0
			var at_across := 0.5
			while at_across < street:
				if not _solid_across(shape, stands, axis, placed, across, at_across):
					open += 1
				at_across += 1.0
			t.check(open == 0, "%s leaves %d px of its street open" % [name, open])

## Whether `shape`, standing at `stands` with its spine along `axis`, is solid at the point on the
## line across the street through `placed` that lies `at_across` along `across`.
func _solid_across(shape: GroundShape, stands: Vector2, axis: Vector2, placed: Vector2,
		across: Vector2, at_across: float) -> bool:
	var point := placed + across * (at_across - placed.dot(across))
	var local := point - stands
	var spine := Vector2(local.dot(axis), local.dot(axis.orthogonal()))
	return shape.distance_to_spine(spine) <= shape.rounding_radius()

## Stationary seal vehicles have a side picture and an end picture of their own. Side art fits the
## circular body's diameter, while end art keeps the narrower projection instead of stretching into
## a square. Which of the two a vehicle shows on its street is `tests/test_body_stance.gd`'s.
func _test_stationary_vehicles_have_a_side_and_an_end_picture(t: TestRunner) -> void:
	var vehicle_looks: Array[EventDef.Look] = [
		EventDef.Look.MOVING_VAN,
		EventDef.Look.BURNT_OUT_CAR,
	]
	for look in vehicle_looks:
		var id := "moving_van" if look == EventDef.Look.MOVING_VAN else "burnt_out_car"
		var def := EventCatalogue.by_id(id)
		var side := EventPictures.stationary_vehicle_texture(look, true)
		var end := EventPictures.stationary_vehicle_texture(look, false)
		var side_extent := EventPictures.stationary_vehicle_extent(
				side, true, def.obstructs_within() * 2.0)
		var end_extent := EventPictures.stationary_vehicle_extent(
				end, false, def.obstructs_within() * 2.0)
		t.check(side != end, "'%s' has distinct side and end artwork" % def.id())
		t.check(is_equal_approx(side_extent.x, def.obstructs_within() * 2.0),
				"'%s' side view fits the diameter of its solid body" % def.id())
		t.check(end_extent.is_equal_approx(EventPictures.native_size(end))
				and end_extent.x < side_extent.x,
				"'%s' end view keeps its narrower authored projection" % def.id())

## **A whole-scene hard seal has to use a distinct authored picture on either axis.**
## `EventPictures.wide_scene_texture` is the pure selector this pins: on an east-west street
## (`vertical` true) it returns the directional asset. That the drawn body spans the obstruction
## at the ground point is `tests/test_event_views.gd`'s, read off what a `fallen_tree` drawn on
## either axis was told to draw.
func _test_a_wide_scene_faces_its_street(t: TestRunner) -> void:
	var horizontal := EventPictures.wide_scene_texture(EventDef.Look.FALLEN_TREE, false)
	var vertical := EventPictures.wide_scene_texture(EventDef.Look.FALLEN_TREE, true)
	t.check(horizontal == EventPictures.FALLEN_TREE,
			"a north-south street draws the horizontally-composed picture")
	t.check(vertical == EventPictures.FALLEN_TREE_VERTICAL,
			"an east-west street draws its directional picture, not the same one relabelled")
	t.check(horizontal != vertical, "and the two are not the same asset")

	# The other two whole-scene rows carry the same guarantee — checked once each rather than
	# re-running the segment arithmetic, since `wide_scene_texture`'s own match is what could
	# regress silently if a future picture forgot its vertical sibling.
	for look: EventDef.Look in [EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN]:
		var wide := EventPictures.wide_scene_texture(look, false)
		var tall := EventPictures.wide_scene_texture(look, true)
		t.check(not wide.is_empty() and not tall.is_empty() and wide != tall,
				"look %d has two distinct assets, one per street orientation" % look)

	# `""`, not `null`: a picture is a repository path here, and "no authored contact art" is an
	# empty one. Asked as `is_empty()` rather than against `null`, which a `String` is never equal
	# to — the shape that made the fallen tree's check below fail and the crash's pass vacuously.
	var crash_wide := EventPictures.wide_scene_texture(EventDef.Look.CAR_ACCIDENT, false)
	var crash_tall := EventPictures.wide_scene_texture(EventDef.Look.CAR_ACCIDENT, true)
	t.check(not EventPictures.wide_scene_shadow(crash_wide).is_empty()
			and not EventPictures.wide_scene_shadow(crash_tall).is_empty(),
			"both crash directions carry contact shadows instead of a street-wide slab")
	t.check(EventPictures.wide_scene_shadow(
			EventPictures.wide_scene_texture(EventDef.Look.FALLEN_TREE, false)).is_empty(),
			"a continuous fallen tree keeps the generic wide-scene shadow")

## **A crash is two cars, solid to less than the street it closes.** *(2026-09-12: "a car crash
## right now has a full bounding box even though there are gaps in the sprite. the bounding box
## should only be the crashed cars".)* Where its cars stand on a street, and the lanes that leaves
## her, is `tests/test_body_stance.gd`'s; that a live crash registers a collision shape per car is
## `tests/test_event_phase.gd`'s.
func _test_a_crash_is_two_cars_solid_inside_the_street_it_closes(t: TestRunner) -> void:
	var crash := EventCatalogue.by_id("car_accident")
	t.check(crash.body().declared_pieces().size() == 2, "a crash is two cars, so it puts down two bodies")
	t.check(crash.solid_reach() < crash.obstructs_within(),
			"and it is solid to %.0fpx inside the %.0fpx of street it closes"
			% [crash.solid_reach(), crash.obstructs_within()])

## Every other row is exactly one piece at its own origin, so nothing but the crash changed shape.
func _test_every_other_row_is_one_body(t: TestRunner) -> void:
	for def in CatalogueRows.every():
		if def.body().declared_pieces().size() > 1:
			continue
		var expected := 1 if def.body().ground_shape() != null else 0
		t.check(def.body().pieces().size() == expected,
				"'%s' is one body, or none where it has no shape (%d)" % [def.id(), expected])
		if def.obstructs_within() > 0.0:
			t.check(is_equal_approx(def.solid_reach(), def.obstructs_within()),
					("'%s' is solid exactly as far as it closes ground (%.1f vs %.1f): the two "
					+ "readings of a body only come apart for a row that is several")
					% [def.id(), def.solid_reach(), def.obstructs_within()])

## No two rows draw the same picture, and the rows that draw nothing are named.
##
## The `NONE` exemption is spelled out rather than skipped, because `look` has no useful default
## any more — a row that forgets to choose one is invisible, which is the quietest way for an
## event to stop working.
func _test_no_two_rows_draw_the_same_picture(t: TestRunner) -> void:
	# Two rows are legitimately invisible: something else already draws the ground they stand
	# on, or a mast's own picture carries its curfew announcement too (`EventCatalogue.
	# _curfew_announce()`). The finale's explosion has a picture of its own and draws it only in its
	# screen-edge badge: the whole of the row is that it happens somewhere she cannot see, and what
	# it leaves behind is a different row.
	var invisible := ["playground", "curfew_announce"]
	var explosion := EventCatalogue.by_id("finale_explosion")
	t.check(explosion.picture() == EventDef.Look.EXPLOSION
			and not explosion.look().is_drawn_in_the_world(),
			"'finale_explosion' is drawn only in its badge, nothing of it in the world")
	var owner_of := {}
	for def in CatalogueRows.every():
		if def.picture() == EventDef.Look.NONE:
			t.check(invisible.has(def.id()), "'%s' draws nothing on purpose" % def.id())
			continue
		t.check(not owner_of.has(def.picture()),
				"'%s' has a picture of its own (else shared with '%s')"
				% [def.id(), owner_of.get(def.picture(), "")])
		owner_of[def.picture()] = def.id()
	for id: String in invisible:
		var def := EventCatalogue.by_id(id)
		t.check(def != null and def.picture() == EventDef.Look.NONE,
				"'%s' is still one of the invisible ones" % id)
	t.check(owner_of.size() >= 25,
			"and the catalogue draws %d different things" % owner_of.size())

## And no two of those pictures are the same texture.
##
## The half a `look` field cannot enforce by itself: two looks whose `_draw_*` reach for the same
## sprite are the old failure with more enum rows in front of it. `EventPictures.icon_for()` is
## the one table of what a look *is*, and it is also what the screen-edge badge draws — so this
## asserts the badge can never again show a delivery van for a fire engine.
func _test_every_look_carries_its_own_silhouette(t: TestRunner) -> void:
	var seen := {}
	for def in CatalogueRows.every():
		if def.picture() == EventDef.Look.NONE:
			continue
		var icon := EventPictures.icon_for(def.picture())
		t.check(not icon.is_empty(), "'%s' has a silhouette a badge could draw" % def.id())
		if icon.is_empty():
			continue
		t.check(not seen.has(icon),
				"'%s' draws %s, which nothing else draws (else '%s')"
				% [def.id(), icon.get_file(), seen.get(icon, "")])
		seen[icon] = def.id()

## **A row drawn on a building stands nothing on the sidewalk**: no body and no shadow where the
## row is sited, since its picture is on the building behind it. `docs/EVENTS.md`, "Solid things
## are solid": *"a body that disagrees with the picture is a lie about where she can walk,
## whichever way it lies"*, and an invisible body in front of day 8's burnt building is exactly that
## (olive-koala, statement 4: *"the *building* is what needs to be burnt *not* an object next to the
## building!"*).
func _test_a_row_drawn_on_a_building_stands_nothing_on_the_sidewalk(t: TestRunner) -> void:
	for id in _DRAWN_ON_A_BUILDING:
		var def := EventCatalogue.by_id(id)
		t.check(def != null, "the catalogue carries '%s'" % id)
		if not def:
			continue
		t.check(def.obstructs_within() <= 0.0 and def.solid_reach() <= 0.0,
				"'%s' has no body on the sidewalk (obstructs %.0f)" % [id, def.obstructs_within()])
		t.check(not def.look().casts_a_shadow(), "and casts no shadow there")

## **A one-shot is sited on her way, or it is refused** (`EventDef.is_a_one_shot_off_her_way()`,
## which `EventDef.validate()` refuses a row for): a set piece has to be met wherever she goes, and
## one placed at dawn would be met only if she walked there. Day 3's fire, sited from her walk, keeps
## the rule; the same row with its `on_her_way` taken off breaks it; a recurring row with none keeps
## it, since the rule is about one-shots.
func _test_a_one_shot_is_sited_on_her_way(t: TestRunner) -> void:
	var fire := EventCatalogue.by_id("burning_building")
	t.check(not fire.is_a_one_shot_off_her_way(), "day 3's fire, sited from her walk, keeps the rule")
	var unsiting := fire.redraft()
	unsiting.not_sited_from_her_walk()
	var unsited := unsiting.build()
	t.check(unsited.is_a_one_shot_off_her_way(),
			"the same one-shot not sited from her walk is refused")
	t.check(not EventCatalogue.by_id("delivery_van").is_a_one_shot_off_her_way(),
			"a recurring row not sited from her walk keeps it")

## **A row is weighed only on ground it stands on**
## (`EventDef.is_weighed_on_ground_it_cannot_stand_on()`, which `EventDef.validate()` refuses a row
## for): every catalogue row keeps the rule, and a row standing on the sidewalk alone weighed on an
## alley breaks it.
func _test_a_row_is_weighed_only_on_ground_it_stands_on(t: TestRunner) -> void:
	var stray: Array[String] = []
	for def in CatalogueRows.every():
		if def.is_weighed_on_ground_it_cannot_stand_on():
			stray.append(def.id())
	t.check(stray.is_empty(), "every catalogue row is weighed only where it stands (%s)" % [stray])
	var stray_draft := EventDraft.new("bad")
	stray_draft.ground([GameEnums.TileType.SIDEWALK] as Array[int])
	stray_draft.weighed_on(PlacementGround.Kind.ALLEY, 0.5)
	var bad := stray_draft.build()
	t.check(bad.is_weighed_on_ground_it_cannot_stand_on(),
			"a sidewalk row weighed on an alley is refused")

## **Every copy of a row keeps its weights on the kinds of ground** (`EventDef.weight_on()`): the
## charging dog's copy from day 4 on (`for_day()`, which hands a placement past its day switch a
## copy) and a heated copy (`at_heat()`) of a pressing row weighed on a street answer the row's own
## weight on every ground, and each row's weight on some ground is one the catalogue set, under one,
## not the one its tiles alone would give.
func _test_every_copy_of_a_row_keeps_its_ground_weights(t: TestRunner) -> void:
	var grounds: Array[PlacementGround.Kind] = [PlacementGround.Kind.STREET,
			PlacementGround.Kind.JUNCTION, PlacementGround.Kind.ALLEY, PlacementGround.Kind.OPEN]
	var dog := EventCatalogue.by_id("charging_dog")
	var pressing_draft := EventDraft.new("pressing")
	pressing_draft.ground([GameEnums.TileType.SIDEWALK] as Array[int])
	pressing_draft.hunt(HuntSpec.pressing())
	pressing_draft.weighed_on(PlacementGround.Kind.STREET, 0.25)
	var pressing := pressing_draft.build()
	for pair: Array in [[dog, dog.for_day(4)], [pressing, pressing.at_heat(Tuning.RESISTANCE_GOAL,
			EventCatalogue.charger_timing())]]:
		var row: EventDef = pair[0]
		var copy: EventDef = pair[1]
		var set_under_one := false
		var kept := true
		for ground in grounds:
			set_under_one = set_under_one or (row.weight_on(ground) > 0.0
					and row.weight_on(ground) < 1.0)
			kept = kept and copy.weight_on(ground) == row.weight_on(ground)
		t.check(copy != row and set_under_one, "'%s' is copied, and weighed under one on a ground"
				% row.id())
		t.check(kept, "and its copy keeps its weight on every kind of ground")
