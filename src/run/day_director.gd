class_name DayDirector
extends RefCounted
## Starts a day and ends it: the one start every spec goes through — the fourteen days, an authored
## scene's day and both sections of the escape (`start()`) — and the one place a day's outcome is
## decided (`finish_day()`). `RunFlow` has it start each walk; `main` and the tests build it.
##
## **One start, and what differs is the spec's settings.** *(minty-lemur #785: "the escape is just
## like a normal day with some special settings"; inbox #1268.)* Every walk takes the same steps in the
## same order: the spec to the clock; the spec's world asked for, and what the walk is won at in it
## handed on; the world dressed for the day; the events planned; the resistance started, or an authored scene installing itself instead; her put
## down and the crowd started; the clock started. Whether the dawn is photographed, whether the
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
## clock and the run — it reads the events, the city, the player and the baby where there are some,
## from the world `start()` stood or the one `use_the_world()` handed. It calls no observer: every
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
## It writes no save and shows no screen: `finish_day()` returns a `DayEnd` and `main` saves and
## shows.

## The run's calendar, handed in.
var calendar: RunCalendar
var config: RunConfig
var city: City
var events: EventManager
var resistance: ResistanceDirector
var player: Stroller
var baby: Baby
var day: DayController
## The facts and the spend the run holds, handed in beside the calendar.
var _facts: RunFacts
var spend: AttemptSpendState
## Whether this is the boot's first walk, a section of the escape included: the only one the
## developer's start flags decide, and those (`--spawn`, `--meters`) only a walk from her doorstep.
var first_day := false
## False for a scene recipe, whose won last day reloads the authored scene instead of the escape.
var escape_follows := true
## The day being walked, set by `use_the_day()`.
var spec := DaySpec.new()
## Where every walk's world comes from, handed in by `use_worlds()`.
var _worlds := DayWorldSource.new()
## The authored scene this boot plays (a scene recipe's playback), which installs its own day in
## place of the plan, or null for the game's own run. Handed in by `use_the_scene()`.
var _scene: AuthoredScene
## Where the director's own line about a planned walk goes in the run log, handed in by
## `use_trace()`; nowhere until then.
var _trace := RunTrace.new()

func _init(the_calendar: RunCalendar, the_facts: RunFacts, the_spend: AttemptSpendState,
		the_config: RunConfig) -> void:
	calendar = the_calendar
	config = the_config
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

## Hands the world the day is walked in, and the resistance and the day's clock. `events` is the
## events of whichever world she is in: the city's, or the escape's building's; they and the
## resistance are handed her too. `start()` hands itself the world it stands; `finish_day()` reads
## whichever was handed last.
func use_the_world(the_city: City, the_events: EventManager, the_resistance: ResistanceDirector,
		the_player: Stroller, the_baby: Baby, the_day: DayController) -> void:
	city = the_city
	events = the_events
	resistance = the_resistance
	player = the_player
	baby = the_baby
	day = the_day
	if events:
		events.use_player(player)
	if resistance:
		resistance.use_player(player)

## The day about to be walked, handed to the day's clock.
func use_the_day(the_spec: DaySpec) -> void:
	spec = the_spec
	day.spec = the_spec

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
	var today: int = calendar.header.day
	use_the_day(the_spec)
	# Before the announcement and before anything is placed: this is where the run photographs
	# what the resistance had done, and a lost day gives exactly that back — so the photograph has
	# to be taken while it is still true of the attempt about to be played. See
	# `RunCalendar.begin_day()`.
	if spec.photographs_the_dawn():
		calendar.begin_day()
	# The walk is announced first, so listeners clear yesterday's state before anything is placed
	# in today — announcing it afterwards wiped the contact the director had just reported, and the
	# HUD showed nothing — and before its world is stood, so whatever the escape's building or city
	# does as it is built (the escape's city goes dark as it is built) is already counted as this
	# walk's.
	if started.is_valid():
		started.call()
	var world := _worlds.stand(spec)
	# The world announced as it stands, before anything is dressed or placed in it: the run log heads
	# the walk here, with what only the world can name (a day's city seed), and watches it from here,
	# so the lines the dressing and the plan write are under the walk's own header.
	if stood.is_valid():
		stood.call(world)
	use_the_world(world.city(), world.events(), resistance, world.player(), world.baby(), day)
	# What the walk is won at, as the world it stands in answers it: the ways out, which the clock
	# reads off the spec it was just handed, and her and her front door's map, which it reads itself.
	spec.use_exits(world.exits())
	day.use_the_walk(world.home_map(), world.player())
	# The city becomes today's city before anything is placed in it: the scheduler has to see the
	# parks that are still parks, not yesterday's.
	if city:
		_dress_the_city(today)
	var errors: Array[String] = []
	if _scene:
		# Over a running clock, as a played day's sleep would come: a scene that puts the baby to
		# sleep at its start has her owe the walk home on a day.
		day.start(spec.seconds_on_the_clock())
		# The scene's events run under the very spec the clock and the HUD were just handed.
		errors = _scene.install(city, player, baby, spec, resistance)
		if errors.is_empty():
			prepare_city_scenery(city, player)
	else:
		_plan_the_walk(world, today)
		_put_her_down(world, today)
		_print_the_start(Time.get_ticks_msec() - elapsed)
	return errors

## The city dressed for the day `spec` is: the run's city state brought to today, the act's spent
## calm handed over where the spec shuts it, the repaint and the closures (`City.start_day()`), the
## act's cast and, where the light does not run down, the night.
func _dress_the_city(today: int) -> void:
	spend.city_state.begin_day(city.map.block_plans, today)
	if spec.shuts_the_spent_calm():
		# The calm areas she has used this act, handed to the repaint `city.start_day()` opens with,
		# so the ones that can be shut are shut before the day's route tree is grown around them.
		# See `CityMap.set_spent_calm()`.
		city.map.set_spent_calm(calendar.settled_this_act())
		# What the run already remembers about the one park barriers ever stand around this run,
		# handed over the same way, so a fence chosen on an earlier day of this act stands again
		# today rather than being re-decided. See `CityMap.set_fenced_park_state()`.
		city.map.set_fenced_park_state(_facts.fenced_park, _facts.fenced_park_act,
				calendar.current_act())
	# An authored scene's city closes the recipe's own streets rather than growing a day's
	# (`City.start_recipe_day()`); a walk that closes none is dressed the same either way.
	if _scene and spec.closes_the_streets():
		city.start_recipe_day(spend.city_state, today, calendar.day_rng(today, "closures"), spec)
	else:
		city.start_day(spend.city_state, today, calendar.day_rng(today, "closures"), spec)
	if spec.shuts_the_spent_calm():
		# Remember the first choice for the run. Today's physical fence disappears after its act,
		# but that must not erase the history and allow tomorrow to choose another one.
		_facts.remember_fenced_park(city.map.fenced_park, city.map.fenced_park_act)
	city.set_act(calendar.current_act())
	# Night, and fixed there: the escape happens after the last day and the clock is the tension
	# rather than the light, so the sky does not run itself down over the sequence.
	if not spec.runs_the_daylight_down():
		city.set_daylight(0.0)

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
		rng = calendar.day_rng(today, spec.events_stream())
	var none: Array[String] = []
	events.start_day(spec, rng, spend.consumed_one_shots if spec.spends_the_one_shots() else none,
			world.start_position())
	if not city:
		return
	# The day's seals are planned inside the call above, and a `fallen_tree_seal` takes a street
	# tree's own pit. `City.start_day` already emptied the pits its own closures took, so this is
	# the second half of one refresh rather than a repair of it — see `City.refresh_street_trees`.
	city.refresh_street_trees()
	if spec.closes_the_streets():
		return
	# **The kerb tint follows the plan's walk.** A day's tree is tinted as it is grown
	# (`City._close_streets()`); a walk handed in — the escape's two chains — is tinted once it is
	# planned, on every start of the section, a restart's included.
	var walk := events.walk() as FinalePlanner.Plan
	city.tint_the_route(walk)
	# Written as well as printed: the shape of the walk is the one thing worth knowing before
	# anything else in the log means anything, and a run with telemetry off still has a console.
	var summary := walk.summary(events.plans().size())
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
	if resistance and spec.runs_the_resistance():
		resistance.start_day(today, calendar.day_rng(today, "resistance"),
				spec.seconds_on_the_clock())
	var flags_decide := first_day and spec.start_point() == DaySpec.Start.DOORSTEP
	var start_at := world.start_position()
	if flags_decide:
		start_at = DevRig.for_spawn_target(config.spawn_target, city, resistance, calendar.header)
	events.stream_around(start_at)
	if city:
		_start_the_crowd(start_at, today)
		# The smallest wiring for the checkpoint gates: `DayStreets.region_plan()` is already valid
		# by here (`city.start_day()` built it above), so the crowd just needs to be told where
		# today's gates are — empty before `Tuning.REGION_WALL_FIRST_DAY`, which is a harmless no-op
		# day for `Crowd`. A walk that grows no tree stands no wall and has no gates.
		if city.streets().region_plan():
			city.crowd.set_gates(city.streets().region_plan().gates)
	player.reset_at(start_at, world.start_facing())
	prepare_city_scenery(city, player)
	baby.reset()
	if spec.starts_with_the_baby_asleep():
		baby.force_sleep()
	day.start(spec.seconds_on_the_clock())
	# After the day is running, not before: the override can put the baby straight to
	# sleep, and start() would have reset the phase that announcement just set.
	if flags_decide:
		DevRig.apply_meter_override(baby, config.meters_override)

## The console's line for a walk just started, `ms` after the start began: what was planned and, in a
## city, who is on its streets and what is calm and closed.
func _print_the_start(ms: int) -> void:
	if city:
		print("[Main] day %d started in %d ms (act %d): %d events (%d live, %d ahead), %d crowd, %.0fs "
				% [spec.day_number(), ms, calendar.current_act(), events.planned_count(),
				events.active_count(), events.owed_ahead(), city.crowd.agent_count(), day.time_total]
				+ "| calm: %s | closed: %s" % [city.calm_summary(), city.closure_summary()])
	else:
		print("[Main] day %d started in %d ms (act %d): %d events (%d live, %d ahead), %.0fs"
				% [spec.day_number(), ms, calendar.current_act(), events.planned_count(),
				events.active_count(), events.owed_ahead(), day.time_total])

## Today's crowd, as dense as the spec says (`DaySpec.crowd_share()`), built round `at`: a day's
## whole crowd, or nobody at all — a cleared crowd that is never started, the escape's *"no regular
## cars or regular people on the street"*.
func _start_the_crowd(at: Vector2, today: int) -> void:
	var share := spec.crowd_share()
	if share <= 0.0:
		city.crowd.clear()
		return
	city.crowd.start_day(today, calendar.day_rng(today, "crowd"), at, true, false, false,
			share, share)

## **The one place a day ends, the escape's sections included**: the won last night's fire, what
## ended it, the charges still running closed, `day_ended` with its cause — which the run log and the
## page's counter both hear — and, for an ordinary day, what the calendar does next. Returns what
## was settled; the save and the screen are the caller's. *(minty-lemur #785: "losing an escape
## should still state the reason like the rest of the game. nothing should be different.")*
func finish_day(result: GameEnums.DayResult) -> DayEnd:
	var end := DayEnd.new()
	end.result = result
	# A day's number is the calendar's; a section's is its own, after the last day.
	end.finished_day = calendar.header.day if spec.section_kind() == DaySpec.Section.NONE \
			else spec.day_number()
	# Captured here, before anything below touches the clock, so the summary reads the instant
	# the day actually ended. Clamped because `_process()` can call `_end()` one frame after
	# `time_remaining` has gone slightly negative.
	end.elapsed_seconds = clampf(day.time_total - day.time_remaining, 0.0, day.time_total)
	end.reason = day.failure_reason
	end.exit_reached = day.exit_reached
	# **A day she wins with day 3's fire never met still burns.** The row's only day is day 3 and it
	# is spent when it enters the world, so a won day on which every siting was refused would leave
	# the run with no fire, no scar and no shell for day 4 to come out to. Lit here, off her path,
	# on a site the dawn rules accept — before the day's end below, since it happened in the day
	# rather than after it, and before `RunCalendar.finish_day()`, which is what commits a won
	# day's spending. A lost day gives everything back, so it is asked of a win only. See
	# `EventManager.light_what_she_never_met()`. Only a day walked home has one.
	if result == GameEnums.DayResult.WON and player and city \
			and spec.goal_kind() == DaySpec.Goal.HOME:
		city.events.light_what_she_never_met(player.global_position)
	# What ended the day, read once in the frame it ended (see `landed_by_group()`).
	end.cause = _loss_cause(result)
	# Every charge still running ends for the page's charging counter, cut short by the day, on the
	# day it was charged — a section she walks out of or loses as much as a day.
	if events:
		events.end_the_charges_still_running()
	# The one place a day's attempt ends, with everything about it. Before the calendar moves, so
	# the outcome is written above the nerve it cost.
	EventBus.day_ended.emit(end.finished_day, result, end.cause, end.elapsed_seconds)
	if spec.section_kind() != DaySpec.Section.NONE:
		end.is_section = true
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
		end.hands_over_to_the_escape = true
		return end
	# Asked before `finish_day()`, which is what goes back: whether this loss spends a normal run's
	# last nerve, so the summary says where she is going rather than that she tries the day again.
	end.goes_back = result != GameEnums.DayResult.WON \
			and calendar.a_loss_goes_back_to_the_checkpoint()
	end.run_over = not calendar.finish_day(result)
	return end

## Whether the day that just ended is the one the escape follows: **won, the last day, and every
## task complete**. *"After completing all tasks"*, and what that already means in this game is
## `RunCalendar.earned_good_ending()` — so the escape is reached by exactly the runs the good
## ending was reached by. A recipe never hands over (`escape_follows`): its won day reloads the
## authored scene.
func _hands_over_to_the_escape(result: GameEnums.DayResult) -> bool:
	if not escape_follows:
		return false
	return result == GameEnums.DayResult.WON and calendar.is_final_day() \
			and calendar.earned_good_ending()

## What ended a crying or hard-fail day, or "" for a win or a timeout. Reads the world only for the
## result that needs it; the rules are `LossCause`'s.
func _loss_cause(result: GameEnums.DayResult) -> String:
	match result:
		GameEnums.DayResult.LOST_HARD_FAIL:
			return LossCause.of(result, day.hard_fail_reason,
					events.what_struck_her() if events else "")
		GameEnums.DayResult.LOST_CRYING:
			return LossCause.of(result, "", "", landed_by_group())
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
func landed_by_group() -> Dictionary:
	var by_group := {}
	if events:
		# Each live event's own `landed()` under the name the logs give it
		# (`EventInstance.logged_name()`), so a pelican's share is `pelican`'s rather than added to
		# the cyclists' *(inbox #527 in azure-tapir)*. Only positive shares are kept.
		for instance in events.instances():
			var points := instance.excitement.landed()
			if points > 0.0:
				var name := instance.logged_name()
				by_group[name] = float(by_group.get(name, 0.0)) + points
	if city and city.crowd:
		for agent: CrowdAgent in city.crowd.agents():
			var points := agent.excitement.landed()
			if points <= 0.0:
				continue
			var key := "traffic" if agent.kind == CrowdAgent.Kind.CAR else "crowd"
			by_group[key] = float(by_group.get(key, 0.0)) + points
	if baby:
		var self_points := baby.self_landed()
		if self_points > 0.0:
			by_group["self"] = float(by_group.get("self", 0.0)) + self_points
	return by_group

## Lifecycle relocations prepare the destination before play/brief reveal, including dev spawns
## and the escape's camera handoff from the interior. Nothing to prepare for a world with no
## scenery, or a player outside the tree, which has no viewport to measure — never the case in the
## running game.
static func prepare_city_scenery(the_city: City, the_player: Stroller) -> void:
	if not the_city or not the_city.scenery or not the_player or not the_player.is_inside_tree():
		return
	var camera: Camera2D = the_player.get_node("Camera2D")
	camera.force_update_scroll()
	var size := the_player.get_viewport_rect().size / camera.zoom
	var angle := camera.global_rotation
	var world_size := Vector2(absf(cos(angle)) * size.x + absf(sin(angle)) * size.y,
			absf(sin(angle)) * size.x + absf(cos(angle)) * size.y)
	the_city.scenery.update(Rect2(camera.get_screen_center_position() - world_size * 0.5,
			world_size), true)
