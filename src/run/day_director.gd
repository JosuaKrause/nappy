class_name DayDirector
extends RefCounted
## Starts a day and ends it: the one start every spec goes through — the fourteen days, an authored
## scene's day and both sections of the escape (`start()`) — and the one place a day's outcome is
## decided (`finish_day()`). `RunFlow` has it start each walk; `main` and the tests build it.
##
## **One start, and what differs is the spec's settings.** *(minty-lemur #785: "the escape is just
## like a normal day with some special settings"; inbox #1268 in olive-ferret.)* Every walk takes
## the same steps in the same order: the spec to the clock; the spec's world asked for, and what the
## walk is won at in it handed on; the world dressed for the day; the events planned; the resistance
## started, or an authored scene installing itself instead; her put down and the crowd started; the
## clock started. Whether the dawn is photographed, whether the
## resistance runs, whether the baby starts asleep and where she starts are the spec's to say
## (`DaySpec.photographs_the_dawn()`, `runs_the_resistance()`, `starts_with_the_baby_asleep()`,
## `start_point()`), never a question of which walk this is.
##
## **Handed everything, reads nothing global.** The world comes from the `DayWorldSource` it is handed
## (`use_worlds()`), which stands it — the day's city, the escape's building or the escape's city —
## and the director fetches nothing from the tree, a group or an autoload for it. What the walk is won
## at is the world's answer too, and the director hands it on: the ways out to the spec
## (`DayWorld.exits()`), her and the map her front door is on to the day's clock
## (`DayWorld.home_map()`), so a source stands a world and writes into nothing. What each call
## requires differs: `start()` requires the worlds, the day's clock and, on a walk that runs it, the
## resistance; `finish_day()` ends any day, a section of the building included, and requires only the
## clock and the run — it reads the events, the city's crowd, the player and the baby where there are
## some, from the world `start()` stood or the one `use_the_world()` handed. It calls no observer: every
## observer hears the walk from `RunFlow`, which `start()` tells through the two callbacks it is
## handed — once the dawn is photographed and before the world stands, and once the world stands,
## before anything is dressed or placed in it — and which announces the walk planned once `start()`
## returns.
##
## `calendar` is the run's calendar and its operations (the dawn photograph, `settled_this_act()`,
## `day_rng()`, a day's `finish_day()`), handed in by whoever builds the director rather than reached
## for as a global, with the run's facts and spend beside it. A test hands the parts of a fresh
## `RunState.new()`; the director is never handed the run itself.
##
## **The city's parts, never the city** *(inbox #1156 in gray-dolphin: "the city should never be built
## for tests that don't test the actual city")*: what it reads of a city world comes out of the
## world as parts of their own — the map, today's streets (`DayStreets`), the crowd and the city
## scene's dressing for the day (`CityDressing`) — so a test stands a world of fakes, and none is
## a `City`. An authored scene alone is handed the city whole (`DayWorld.scene_city()`).
##
## It writes no save and shows no screen: `finish_day()` returns a `DayEnd` and `main` saves and
## shows.

## The run's calendar, handed in.
var calendar: RunCalendar
var _events: EventManager
var resistance: ResistanceDirector
var _player: Stroller
var baby: Baby
var _day: DayController
## Whether the world being walked is a city (`DayWorld.is_in_a_city()`): the one answer every
## city branch below keys on. False in the escape's building and before any world is handed.
var _in_a_city := false
## The city's parts in the world being walked, all four there in a city and null in any other world,
## taken from the world `use_the_world()` hands: its map, today's streets, its crowd and what
## dresses it for the day.
var _city_map: CityMap
var _streets: DayStreets
var _crowd: Crowd
var _dressing: CityDressing
## The facts and the spend the run holds, handed in beside the calendar.
var _facts: RunFacts
var spend: AttemptSpendState
## Whether this is the boot's first walk, a section of the escape included: the only one the
## developer's start flags decide, and those (`--spawn`, `--meters`) only a walk from her doorstep.
## Handed in by `use_first_day()`.
var _first_day := false
## False for a scene recipe, whose won last day reloads the authored scene instead of the escape.
## Handed in by `use_escape_follows()`.
var _escape_follows := true
## The day being walked: handed in by `use_the_spec()` for a director built to finish it, and set
## by `start()` for one that starts it.
var _spec := DaySpec.new()
## Where every walk's world comes from, handed in by `use_worlds()`.
var _worlds := DayWorldSource.new()
## The authored scene this boot plays (a scene recipe's playback), which installs its own day in
## place of the plan, or null for the game's own run. Handed in by `use_the_scene()`.
var _scene: AuthoredScene
## Where the director's own line about a planned walk goes in the run log, handed in by
## `use_trace()`; nowhere until then.
var _trace := RunTrace.new()
## Where the developer's flags start her on the boot's first walk from her doorstep: takes nothing
## and answers her start as a `Vector2`, the run's `--spawn` target already bound in; unhanded, she
## starts where the world puts her. Handed in by `use_the_flags()`.
var _flags_start := Callable()
## What the developer's flags do to the baby's bars once the day is running: takes the baby, the
## run's `--meters` override already bound in; unhanded, the bars are untouched. Handed in by
## `use_the_flags()`.
var _flags_meters := Callable()

func _init(the_calendar: RunCalendar, the_facts: RunFacts, the_spend: AttemptSpendState) -> void:
	calendar = the_calendar
	_facts = the_facts
	spend = the_spend

## Hands the director where every walk's world comes from (`DayWorldSource`): the main scene's own,
## or a test's fake.
func use_worlds(worlds: DayWorldSource) -> void:
	_worlds = worlds

## Hands the director the authored scene this boot plays, or null for the game's own run: a scene's
## walk is installed by the scene rather than planned from the run.
func use_the_scene(scene: AuthoredScene) -> void:
	_scene = scene

## Hands the director the trace its line about a planned walk is written to.
func use_trace(trace: RunTrace) -> void:
	_trace = trace

## Hands the director what the developer's flags decide on the boot's first walk from her doorstep:
## `start`, which takes nothing and answers her start (a `Vector2`), and `meters`, which takes the
## baby and seeds its bars. `main` hands both on every boot with the run's `--spawn` target and
## `--meters` override bound in, so the director holds no configuration of its own; a director
## handed neither (a suite's) starts her where the world puts her and leaves the bars alone.
func use_the_flags(start: Callable, meters: Callable) -> void:
	_flags_start = start
	_flags_meters = meters

## Hands the world the day is walked in (`DayWorld`, null for none yet), and the resistance and the
## day's clock: the world's events, her and the baby, and its city's parts where it is a city; its
## events and the resistance are handed her too. `start()` hands itself the world it stands;
## `finish_day()` reads whichever was handed last.
func use_the_world(world: DayWorld, the_resistance: ResistanceDirector,
		the_day: DayController) -> void:
	resistance = the_resistance
	_day = the_day
	_events = world.events() if world else null
	_player = world.player() if world else null
	baby = world.baby() if world else null
	_in_a_city = world != null and world.is_in_a_city()
	_city_map = world.city_map() if world else null
	_streets = world.streets() if world else null
	_crowd = world.crowd() if world else null
	_dressing = world.dressing() if world else null
	if _events:
		_events.use_player(_player)
	if resistance:
		resistance.use_player(_player)

## Hands the director the day being walked, which `finish_day()` ends: `main` hands the run flow's
## own to every director it builds, and `start()` hands itself the one it starts.
func use_the_spec(the_spec: DaySpec) -> void:
	_spec = the_spec

## Hands the director whether this is the boot's first walk, the one the developer's start flags
## decide: `main` hands its own answer to every director it builds.
func use_first_day(first: bool) -> void:
	_first_day = first

## Hands the director whether a won last day hands over to the escape: false for a scene recipe,
## whose won day reloads the authored scene. `main` hands the run flow's answer.
func use_escape_follows(follows: bool) -> void:
	_escape_follows = follows

## The day about to be walked, handed to the day's clock.
func use_the_day(the_spec: DaySpec) -> void:
	use_the_spec(the_spec)
	_day.use_the_spec(the_spec)

## **Starts the walk `the_spec` describes**: a day, an authored scene's day, or a section of the
## escape, the first time or again after a loss. Writes nothing to the save itself: each caller
## decides what, if anything, the save should say about the walk this just started. Returns the
## problems that kept an authored scene's setup from standing, empty when it stands.
##
## **`started` and `stood` are where the walk is announced** (`RunFlow.start()` hands them):
## `started` is called once the dawn is photographed and before the world is stood, `stood` with the
## world once it stands and before anything is dressed or placed in it. Neither is required: a
## start handed none announces nothing.
func start(the_spec: DaySpec, started := Callable(), stood := Callable()) -> Array[String]:
	# Timed for the same reason `_ready()` times `CityGenerator.generate()`: playtest 27 named
	# this path — planning the day's closures, placing every event, streaming the world around
	# the doorstep — as one of the candidates for the wait after a summary's continue button.
	var elapsed := Time.get_ticks_msec()
	var today: int = calendar.day()
	use_the_day(the_spec)
	# Before the announcement and before anything is placed: this is where the run photographs
	# what the resistance had done, and a lost day gives exactly that back — so the photograph has
	# to be taken while it is still true of the attempt about to be played. See
	# `RunCalendar.begin_day()`.
	if _spec.photographs_the_dawn():
		calendar.begin_day()
	# The walk is announced first, so listeners clear yesterday's state before anything is placed
	# in today — announcing it afterwards wiped the contact the director had just reported, and the
	# HUD showed nothing — and before its world is stood, so whatever the escape's building or city
	# does as it is built (the escape's city goes dark as it is built) is already counted as this
	# walk's.
	if started.is_valid():
		started.call()
	var world := _worlds.stand(_spec)
	# The world announced as it stands, before anything is dressed or placed in it: the run log heads
	# the walk here, with what only the world can name (a day's city seed), and watches it from here,
	# so the lines the dressing and the plan write are under the walk's own header.
	if stood.is_valid():
		stood.call(world)
	use_the_world(world, resistance, _day)
	# What the walk is won at, as the world it stands in answers it: the ways out, which the clock
	# reads off the spec it was just handed, and her and her front door's map, which it reads itself.
	_spec.use_exits(world.exits())
	_day.use_the_walk(world.home_map(), world.player())
	# The city becomes today's city before anything is placed in it: the scheduler has to see the
	# parks that are still parks, not yesterday's.
	if _in_a_city:
		_dress_the_city(today)
	var errors: Array[String] = []
	if _scene:
		# Over a running clock, as a played day's sleep would come: a scene that puts the baby to
		# sleep at its start has her owe the walk home on a day.
		_day.start(_spec.seconds_on_the_clock())
		# The scene's events run under the very spec the clock and the HUD were just handed.
		errors = _scene.install(world.scene_city(), world.scene_simulation(), _player, baby, _spec,
				resistance)
		if errors.is_empty():
			_prepare_the_scenery_round_her()
	else:
		_plan_the_walk(world, today)
		_put_her_down(world, today)
		_print_the_start(Time.get_ticks_msec() - elapsed)
	return errors

## The city dressed for the day `_spec` is: the run's city state brought to today, the act's spent
## calm handed over where the spec shuts it, the repaint and the closures
## (`CityDressing.start_day()`), the act's cast and, where the light does not run down, the night.
func _dress_the_city(today: int) -> void:
	spend.block_arcs().begin_day(_city_map.plans_by_block(), today)
	if _spec.shuts_the_spent_calm():
		# The calm areas she has used this act, handed to the repaint `start_day()` opens with,
		# so the ones that can be shut are shut before the day's route tree is grown around them.
		# See `CityMap.set_spent_calm()`.
		_city_map.set_spent_calm(calendar.settled_this_act())
		# What the run already remembers about the one park barriers ever stand around this run,
		# handed over the same way, so a fence chosen on an earlier day of this act stands again
		# today rather than being re-decided. See `CityMap.set_fenced_park_state()`.
		_city_map.set_fenced_park_state(_facts.fenced_park(), _facts.fenced_park_act(),
				calendar.current_act())
	# An authored scene's city closes the recipe's own streets rather than growing a day's
	# (`City.start_recipe_day()`); a walk that closes none is dressed the same either way.
	if _scene and _spec.closes_the_streets():
		_dressing.start_recipe_day(spend.block_arcs(), today, calendar.day_rng(today, "closures"),
				_spec)
	else:
		_dressing.start_day(spend.block_arcs(), today, calendar.day_rng(today, "closures"), _spec)
	if _spec.shuts_the_spent_calm():
		# Remember the first choice for the run. Today's physical fence disappears after its act,
		# but that must not erase the history and allow tomorrow to choose another one.
		_facts.remember_fenced_park(_city_map.fenced_park_block(), _city_map.fenced_park_act())
	_dressing.set_act(calendar.current_act())
	# Night, and fixed there: the escape happens after the last day and the clock is the tension
	# rather than the light, so the sky does not run itself down over the sequence.
	if not _spec.runs_the_daylight_down():
		_dressing.set_daylight(0.0)

## The walk's events planned, around where she starts (`EventManager.start_day()`, one call for every
## kind of walk), on the world's own stream or the spec's stream of the run, spending the run's
## one-shots where the spec does; then, in a city, the second half of the street trees' refresh and,
## where the walk is handed in rather than grown, its kerb tint.
##
## **Events and the contact are placed before her**, so `--spawn` has something to find and so
## nothing spawns on top of her. The plan is the whole walk and the *world* is only what is within
## reach, so where she actually starts decides what exists on the first frame — which is why the
## crowd is populated after her start is settled, and why the events are streamed a second time once
## it is known (`_put_her_down()`).
func _plan_the_walk(world: DayWorld, today: int) -> void:
	var rng := world.plan_rng()
	if not rng:
		rng = calendar.day_rng(today, _spec.events_stream())
	var none: Array[String] = []
	_events.start_day(_spec, rng,
			spend.consumed_one_shots() if _spec.spends_the_one_shots() else none,
			world.start_position())
	if not _in_a_city:
		return
	# The day's seals are planned inside the call above, and a `fallen_tree_seal` takes a street
	# tree's own pit. `City.start_day` already emptied the pits its own closures took, so this is
	# the second half of one refresh rather than a repair of it — see `City.refresh_street_trees`.
	_dressing.refresh_street_trees()
	if _spec.closes_the_streets():
		return
	# **The kerb tint follows the plan's walk.** A day's tree is tinted as it is grown
	# (`City._close_streets()`); a walk handed in — the escape's two chains — is tinted once it is
	# planned, on every start of the section, a restart's included.
	var walk := _events.walk() as FinalePlanner.Plan
	_dressing.tint_the_route(walk)
	# Written as well as printed: the shape of the walk is the one thing worth knowing before
	# anything else in the log means anything, and a run with telemetry off still has a console.
	var summary := walk.summary(_events.plans().size())
	print("[Main] finale planned: %s" % summary)
	_trace.note("plan", "finale: %s" % summary)

## Her put down where the walk starts and the world around her made live: the resistance's day where
## the spec runs it, her start (the developer's `--spawn` on the boot's first walk from her doorstep),
## the events streamed around it, the crowd at the spec's density, her and the baby reset, the baby
## asleep where the spec says so, the clock started.
func _put_her_down(world: DayWorld, today: int) -> void:
	# Before her start is read, not merely before she is placed: `--spawn contact` reads
	# `resistance.contact_position()` directly, and on the first day — the only day `--spawn`
	# decides where she starts — the mark has to already be on offer when this line runs, not
	# merely by the time the day is shown to her.
	if resistance and _spec.runs_the_resistance():
		resistance.start_day(today, calendar.day_rng(today, "resistance"),
				_spec.seconds_on_the_clock())
	var flags_decide := _first_day and _spec.start_point() == DaySpec.Start.DOORSTEP
	var start_at := world.start_position()
	if flags_decide and not _flags_start.is_null():
		start_at = _flags_start.call()
	_events.stream_around(start_at)
	if _in_a_city:
		_start_the_crowd(start_at, today)
		# The smallest wiring for the checkpoint gates: `DayStreets.region_plan()` is already valid
		# by here (the dressing's `start_day()` built it above), so the crowd just needs to be told
		# where today's gates are — empty before `Tuning.REGION_WALL_FIRST_DAY`, which is a harmless
		# no-op day for `Crowd`. A walk that grows no tree stands no wall and has no gates.
		if _streets.region_plan():
			_crowd.set_gates(_streets.region_plan().gate_states())
	_player.reset_at(start_at, world.start_facing())
	_prepare_the_scenery_round_her()
	baby.reset()
	if _spec.starts_with_the_baby_asleep():
		baby.force_sleep()
	_day.start(_spec.seconds_on_the_clock())
	# After the day is running, not before: the override can put the baby straight to
	# sleep, and start() would have reset the phase that announcement just set.
	if flags_decide and not _flags_meters.is_null():
		_flags_meters.call(baby)

## The console's line for a walk just started, `ms` after the start began: what was planned and, in a
## city, who is on its streets and what is calm and closed.
func _print_the_start(ms: int) -> void:
	if _in_a_city:
		print("[Main] day %d started in %d ms (act %d): %d events (%d live, %d ahead), %d crowd, %.0fs "
				% [_spec.day_number(), ms, calendar.current_act(), _events.planned_count(),
				_events.active_count(), _events.owed_ahead(), _crowd.agent_count(),
				_day.seconds_total()]
				+ "| calm: %s | closed: %s" % [_city_map.calm_summary(spend.block_arcs()),
				_streets.closure_summary()])
	else:
		print("[Main] day %d started in %d ms (act %d): %d events (%d live, %d ahead), %.0fs"
				% [_spec.day_number(), ms, calendar.current_act(), _events.planned_count(),
				_events.active_count(), _events.owed_ahead(), _day.seconds_total()])

## Today's crowd, as dense as the spec says (`DaySpec.crowd_share()`), built round `at`: a day's
## whole crowd, or nobody at all — a cleared crowd that is never started, the escape's *"no regular
## cars or regular people on the street"*.
func _start_the_crowd(at: Vector2, today: int) -> void:
	var share := _spec.crowd_share()
	if share <= 0.0:
		_crowd.clear()
		return
	_crowd.start_day(today, calendar.day_rng(today, "crowd"), at, true, false, false,
			share, share)

## **The one place a day ends, the escape's sections included**: the won last night's fire, what
## ended it, the charges still running closed, `day_ended` with its cause — which the run log and the
## page's counter both hear — and, for an ordinary day, what the calendar does next. Returns what
## was settled; the save and the screen are the caller's. *(minty-lemur #785: "losing an escape
## should still state the reason like the rest of the game. nothing should be different.")*
func finish_day(result: GameEnums.DayResult) -> DayEnd:
	# A day's number is the calendar's; a section's is its own, after the last day.
	var finished_day: int = calendar.day() if _spec.section_kind() == DaySpec.Section.NONE \
			else _spec.day_number()
	# Captured here, before anything below touches the clock, so the summary reads the instant
	# the day actually ended. Clamped because `_process()` can call `_end()` one frame after the
	# seconds left have gone slightly negative.
	var elapsed := clampf(_day.seconds_total() - _day.seconds_left(), 0.0, _day.seconds_total())
	var end := DayEnd.new(result, _day.loss_reason(), elapsed, _day.exit_taken())
	# **A day she wins with day 3's fire never met still burns.** The row's only day is day 3 and it
	# is spent when it enters the world, so a won day on which every siting was refused would leave
	# the run with no fire, no scar and no shell for day 4 to come out to. Lit here, off her path,
	# on a site the dawn rules accept — before the day's end below, since it happened in the day
	# rather than after it, and before `RunCalendar.finish_day()`, which is what commits a won
	# day's spending. A lost day gives everything back, so it is asked of a win only. See
	# `EventManager.light_what_she_never_met()`. Only a day walked home has one.
	if result == GameEnums.DayResult.WON and _player and _spec.goal_kind() == DaySpec.Goal.HOME:
		_events.light_what_she_never_met(_player.global_position)
	# What ended the day, read once in the frame it ended (see `_landed_by_group()`).
	var cause := _loss_cause(result)
	# Every charge still running ends for the page's charging counter, cut short by the day, on the
	# day it was charged — a section she walks out of or loses as much as a day.
	if _events:
		_events.end_the_charges_still_running()
	# The one place a day's attempt ends, with everything about it. Before the calendar moves, so
	# the outcome is written above the nerve it cost.
	EventBus.day_ended.emit(finished_day, result, cause, elapsed)
	if _spec.section_kind() != DaySpec.Section.NONE:
		end.mark_a_section()
		return end
	# **The last night hands over rather than ending.** *(PLAYTEST-113: "the escape the building
	# starts when the player has completed all tasks by the end of day 14".)* A won day 14 with
	# every task complete is the good ending, and the good ending is a walk rather than a screen — so
	# `RunCalendar.finish_day()` is deliberately *not* called here: it would end the run on the
	# spot, set `ending`, and clear the save the escape's own checkpoints need.
	if _hands_over_to_the_escape(result):
		# Day 14 is still an ordinary won day, so it still gives a normal run a nerve back — called
		# directly because this is the one day whose win never reaches `finish_day()`.
		calendar.regain_a_nerve_for_a_won_day()
		end.mark_continuing_into_the_escape()
		return end
	# Asked before `finish_day()`, which is what goes back: whether this loss spends a normal run's
	# last nerve, so the summary says where she is going rather than that she tries the day again.
	if result != GameEnums.DayResult.WON and calendar.a_loss_goes_back_to_the_checkpoint():
		end.mark_sending_the_run_back()
	if not calendar.finish_day(result):
		end.mark_ending_the_run()
	return end

## Whether the day that just ended is the one the escape follows: **won, the last day, and every
## task complete**. *"After completing all tasks"*, and what that already means in this game is
## `RunCalendar.earned_good_ending()` — so the escape is reached by exactly the runs the good
## ending was reached by. A recipe never hands over (`use_escape_follows()`): its won day reloads the
## authored scene.
func _hands_over_to_the_escape(result: GameEnums.DayResult) -> bool:
	if not _escape_follows:
		return false
	return result == GameEnums.DayResult.WON and calendar.is_final_day() \
			and calendar.earned_good_ending()

## What ended a crying or hard-fail day, or "" for a win or a timeout. Reads the world only for the
## result that needs it; the rules are `LossCause`'s.
func _loss_cause(result: GameEnums.DayResult) -> String:
	match result:
		GameEnums.DayResult.LOST_HARD_FAIL:
			return LossCause.of(result, _day.hard_fail_reason(),
					_events.what_struck_her() if _events else "")
		GameEnums.DayResult.LOST_CRYING:
			return LossCause.of(result, "", "", _landed_by_group())
	return ""

## The impure half `LossCause.of()`'s crying cause is named for: every live event's own `landed()`
## grouped by its catalogue id, or `pelican` for a pelican, every live crowd agent's grouped by
## `crowd` (a walker) or `traffic` (a car), and the baby's own running/alley share under `self` —
## all over the same `ExcitementSource.WINDOW` the halo itself reads. Only positive shares are kept,
## so an empty result means nothing landed anything in the window at all.
##
## Read once, in the same physics frame `Baby._update_state()` decided she was crying —
## `EventBus.baby_state_changed` -> `DayController._on_baby_state_changed()` -> `_end()` ->
## `day_finished` all run synchronously in that one call, so nothing has aged out of the window.
func _landed_by_group() -> Dictionary:
	var by_group := {}
	if _events:
		# Each live event's own `landed()` under the name the logs give it
		# (`EventInstance.logged_name()`), so a pelican's share is `pelican`'s rather than added to
		# the cyclists' *(inbox #527 in azure-tapir)*. Only positive shares are kept.
		for instance in _events.instances():
			var points := instance.source().landed()
			if points > 0.0:
				var name := instance.logged_name()
				by_group[name] = float(by_group.get(name, 0.0)) + points
	if _in_a_city:
		for agent: CrowdAgent in _crowd.agents():
			var points := agent.mood().landed()
			if points <= 0.0:
				continue
			var key := "traffic" if agent.is_car() else "crowd"
			by_group[key] = float(by_group.get(key, 0.0)) + points
	if baby:
		var self_points := baby.self_landed()
		if self_points > 0.0:
			by_group["self"] = float(by_group.get("self", 0.0)) + self_points
	return by_group

## Lifecycle relocations prepare the destination before play/brief reveal, including dev spawns
## and the escape's camera handoff from the interior: the city's scenery prepared over what her
## camera shows. Nothing to prepare for a world with no city, or a player outside the tree, which
## has no viewport to measure — never the case in the running game.
func _prepare_the_scenery_round_her() -> void:
	if not _in_a_city or not _player or not _player.is_inside_tree():
		return
	var camera: Camera2D = _player.get_node("Camera2D")
	camera.force_update_scroll()
	var size := _player.get_viewport_rect().size / camera.zoom
	var angle := camera.global_rotation
	var world_size := Vector2(absf(cos(angle)) * size.x + absf(sin(angle)) * size.y,
			absf(sin(angle)) * size.x + absf(cos(angle)) * size.y)
	_dressing.prepare_scenery_in(Rect2(camera.get_screen_center_position() - world_size * 0.5,
			world_size))
