class_name DayDirector
extends RefCounted
## Starts a day and ends it: the ordered construction of one day's world, and the one place a day's
## outcome is decided. `main` and the tests both call `start_day(spec)` and `finish_day(result)`.
##
## **Handed everything, reads nothing global.** What each call requires differs, because the escape's
## building is a world with no city, no crowd and no resistance: `start_day()` builds an ordinary day
## and requires the city (whose events it plans), the resistance, the player, the baby and the day's
## clock; `finish_day()` ends any day, a section of the building included, and requires only the clock
## and the run — it reads the events, the city, the player and the baby where there are some. It
## calls no observer: the developer readout, the HUD and the route rig hear the day from `RunFlow`,
## which announces it around `start_day()`.
##
## `run` is the run's state and its calendar operations (the dawn photograph, `settled_this_act()`,
## `day_rng()`, a day's `finish_day()`), handed in by whoever builds the director rather than reached
## for as a global. It is a `RunState`, the class of the `GameState` autoload, so a test hands a fresh
## `RunState.new()`.
##
## It writes no save and shows no screen: `finish_day()` returns a `DayEnd` and `main` saves and
## shows. A scene recipe's day is started by `main` itself.

## The run, handed in.
var run: RunState
var config: RunConfig
var city: City
var events: EventManager
var resistance: ResistanceDirector
var player: Stroller
var baby: Baby
var day: DayController
## The facts and the spend the run holds, taken off its registered parts.
var facts: RunFacts
var spend: AttemptSpendState
## Whether this is the boot's first day, the only one `--spawn` and `--meters` decide.
var first_day := false
## False for a scene recipe, whose won last day reloads the authored scene instead of the escape.
var escape_follows := true
## The day being walked, set by `use_the_day()`.
var spec := DaySpec.new()

func _init(the_run: RunState, the_config: RunConfig) -> void:
	run = the_run
	config = the_config
	facts = run.facts
	spend = run.attempt_spend

## Hands the world the day is walked in. `events` is the events of whichever world she is in: the
## city's, or the escape's building's.
func use_the_world(the_city: City, the_events: EventManager, the_resistance: ResistanceDirector,
		the_player: Stroller, the_baby: Baby, the_day: DayController) -> void:
	city = the_city
	events = the_events
	resistance = the_resistance
	player = the_player
	baby = the_baby
	day = the_day

## The day about to be walked, handed to the day's clock.
func use_the_day(the_spec: DaySpec) -> void:
	spec = the_spec
	day.spec = the_spec

## Builds and starts the day `the_spec` describes; writes nothing itself. Each caller decides what,
## if anything, the save should say about the day this just built.
func start_day(the_spec: DaySpec) -> void:
	# Timed for the same reason `_ready()` times `CityGenerator.generate()`: playtest 27 named
	# this path — planning the day's closures, placing every event, streaming the world around
	# the doorstep — as one of the candidates for the wait after a summary's continue button.
	var elapsed := Time.get_ticks_msec()
	var today: int = run.header.day
	# Decided once, here, and handed to everything that runs on the day's clock as a number.
	var day_length := config.day_length_for(today)
	use_the_day(the_spec)
	# Before the announcement and before anything is placed: this is where the run photographs
	# what the resistance had done, and a lost day gives exactly that back — so the photograph has
	# to be taken while it is still true of the attempt about to be played. See
	# `GameState.begin_day()`.
	run.begin_day()
	# The day is announced first, so listeners clear yesterday's state before anything is
	# placed in today — announcing it afterwards wiped the contact the director had just
	# reported, and the HUD showed nothing.
	EventBus.day_started.emit(today)

	# Events and the contact are placed before the player, so --spawn has something to find
	# and so nothing spawns on top of her.
	# The city becomes today's city before anything is placed in it: the scheduler has to
	# see the parks that are still parks, not yesterday's.
	spend.city_state.begin_day(city.map.block_plans, today)
	# The calm areas she has used this act, handed to the repaint `city.start_day()` opens with, so
	# the ones that can be shut are shut before the day's route tree is grown around them. See
	# `CityMap.set_spent_calm()`.
	city.map.set_spent_calm(run.settled_this_act())
	# What the run already remembers about the one park barriers ever stand around this run,
	# handed over the same way, so a fence chosen on an earlier day of this act stands again today
	# rather than being re-decided. See `CityMap.set_fenced_park_state()`.
	city.map.set_fenced_park_state(facts.fenced_park, facts.fenced_park_act, run.current_act())
	city.start_day(spend.city_state, today, run.day_rng(today, "closures"), spec)
	# Remember the first choice for the run. Today's physical fence disappears after its act,
	# but that must not erase the history and allow tomorrow to choose another one.
	facts.remember_fenced_park(city.map.fenced_park, city.map.fenced_park_act)
	# The day is planned around the doorstep first, because `--spawn event` needs a plan to
	# find an event in. The plan is the whole day and the *world* is only what is within
	# reach, so where she actually starts decides what exists on the first frame —
	# which is why the crowd is populated after the spawn position is settled rather than
	# before it, and why the events are streamed a second time once it is known.
	var doorstep := city.map.doorstep_world_position()
	city.events.use_the_spec(spec)
	city.events.start_day(today, run.day_rng(), spend.consumed_one_shots, doorstep)
	# The day's seals are planned inside the call above, and a `fallen_tree_seal` takes a street
	# tree's own pit. `City.start_day` already emptied the pits its own closures took, so this is
	# the second half of one refresh rather than a repair of it — see `City.refresh_street_trees`.
	city.refresh_street_trees()
	# Before `start_at` is read, not merely before the player is placed: `--spawn contact` reads
	# `resistance.contact_position()` directly, and on the first day — the only day `--spawn`
	# decides where she starts — the mark has to already be on offer when this line runs, not
	# merely by the time the day is shown to her.
	resistance.start_day(today, run.day_rng(today, "resistance"), day_length)
	var start_at := DevRig.for_spawn_target(config.spawn_target, city, resistance, run) \
			if first_day else doorstep
	city.events.stream_around(start_at)
	_start_the_crowd(start_at, today)
	# The smallest wiring for the checkpoint gates: `City.region_plan()` is already valid by here
	# (`city.start_day()` built it above), so the crowd just needs to be told where today's gates
	# are — empty before `Tuning.REGION_WALL_FIRST_DAY`, which is a harmless no-op day for `Crowd`.
	city.crowd.set_gates(city.region_plan().gates)
	city.set_act(run.current_act())
	player.reset_at(start_at)
	prepare_city_scenery(city, player)
	baby.reset()
	day.start(day_length)

	# After the day is running, not before: the override can put the baby straight to
	# sleep, and start() would have reset the phase that announcement just set.
	if first_day:
		DevRig.apply_meter_override(baby, config.meters_override)

	print("[Main] day %d started in %d ms (act %d): %d events (%d live, %d ahead), %d crowd, %.0fs "
			% [today, Time.get_ticks_msec() - elapsed, run.current_act(),
			city.events.planned_count(), city.events.active_count(), city.events.owed_ahead(),
			city.crowd.agent_count(), day.time_total]
			+ "| calm: %s | closed: %s" % [city.calm_summary(), city.closure_summary()])

	# Last, because the day's shape is only true once everything has been placed: the run log
	# writes its plan lines, its dawn picture and her `start` line here.
	EventBus.day_planned.emit(today)

## Today's crowd, as dense as the spec says (`DaySpec.crowd_density`), built round `at`: a day's
## whole crowd, or nobody at all — a cleared crowd that is never started, the escape's *"no regular
## cars or regular people on the street"*. Also the escape's city section's crowd.
func start_the_crowd(at: Vector2) -> void:
	_start_the_crowd(at, run.header.day)

func _start_the_crowd(at: Vector2, today: int) -> void:
	if spec.crowd_density <= 0.0:
		city.crowd.clear()
		return
	city.crowd.start_day(today, run.day_rng(today, "crowd"), at, true, false, false,
			spec.crowd_density, spec.crowd_density)

## **The one place a day ends, the escape's sections included**: the won last night's fire, what
## ended it, the charges still running closed, `day_ended` with its cause — which the run log and the
## page's counter both hear — and, for an ordinary day, what the calendar does next. Returns what
## was settled; the save and the screen are the caller's. *(minty-lemur #785: "losing an escape
## should still state the reason like the rest of the game. nothing should be different.")*
func finish_day(result: GameEnums.DayResult) -> DayEnd:
	var end := DayEnd.new()
	end.result = result
	# A day's number is the calendar's; a section's is its own, after the last day.
	end.finished_day = run.header.day if spec.section == DaySpec.Section.NONE else spec.number
	# Captured here, before anything below touches the clock, so the summary reads the instant
	# the day actually ended. Clamped because `_process()` can call `_end()` one frame after
	# `time_remaining` has gone slightly negative.
	end.elapsed_seconds = clampf(day.time_total - day.time_remaining, 0.0, day.time_total)
	# **A day she wins with day 3's fire never met still burns.** The row's only day is day 3 and it
	# is spent when it enters the world, so a won day on which every siting was refused would leave
	# the run with no fire, no scar and no shell for day 4 to come out to. Lit here, off her path,
	# on a site the dawn rules accept — before the day's end below, since it happened in the day
	# rather than after it, and before `GameState.finish_day()`, which is what commits a won
	# day's spending. A lost day gives everything back, so it is asked of a win only. See
	# `EventManager.light_what_she_never_met()`. Only a day walked home has one.
	if result == GameEnums.DayResult.WON and player and city and spec.goal == DaySpec.Goal.HOME:
		city.events.light_what_she_never_met(player.global_position)
	# What ended the day, read once in the frame it ended (see `landed_by_group()`).
	end.cause = loss_cause(result)
	# Every charge still running ends for the page's charging counter, cut short by the day, on the
	# day it was charged — a section she walks out of or loses as much as a day.
	if events:
		events.end_the_charges_still_running()
	# The one place a day's attempt ends, with everything about it. Before the calendar moves, so
	# the outcome is written above the nerve it cost.
	EventBus.day_ended.emit(end.finished_day, result, end.cause, end.elapsed_seconds)
	if spec.section != DaySpec.Section.NONE:
		end.is_section = true
		return end
	# **The last night hands over rather than ending.** *(PLAYTEST-113: "the escape the building
	# starts when the player has completed all tasks by the end of day 14".)* A won day 14 with
	# every task complete is the good ending, and the good ending is a walk rather than a screen — so
	# `GameState.finish_day()` is deliberately *not* called here: it would end the run on the spot,
	# set `ending`, and clear the save the escape's own checkpoints need.
	if hands_over_to_the_escape(result):
		# Day 14 is still an ordinary won day, so it still gives a normal run a nerve back — called
		# directly because this is the one day whose win never reaches `finish_day()`.
		run.regain_a_nerve_for_a_won_day()
		end.hands_over_to_the_escape = true
		return end
	# Asked before `finish_day()`, which is what goes back: whether this loss spends a normal run's
	# last nerve, so the summary says where she is going rather than that she tries the day again.
	end.goes_back = result != GameEnums.DayResult.WON and run.a_loss_goes_back_to_the_checkpoint()
	end.run_over = not run.finish_day(result)
	return end

## Whether the day that just ended is the one the escape follows: **won, the last day, and every
## task complete**. *"After completing all tasks"*, and what that already means in this game is
## `GameState.earned_good_ending()` — so the escape is reached by exactly the runs the good ending was
## reached by. A recipe never hands over (`escape_follows`): its won day reloads the authored scene.
func hands_over_to_the_escape(result: GameEnums.DayResult) -> bool:
	if not escape_follows:
		return false
	return result == GameEnums.DayResult.WON and run.is_final_day() and run.earned_good_ending()

## What ended a crying or hard-fail day, or "" for a win or a timeout. Reads the world only for the
## result that needs it; the rules are `LossCause`'s.
func loss_cause(result: GameEnums.DayResult) -> String:
	match result:
		GameEnums.DayResult.LOST_HARD_FAIL:
			return LossCause.of(result, day.hard_fail_reason,
					events.what_struck_her() if events else "")
		GameEnums.DayResult.LOST_CRYING:
			return LossCause.of(result, "", "", landed_by_group())
	return ""

## The impure half `LossCause.crying_suffix()` is named for: every live event's own `landed()`
## grouped by its catalogue id, or `pelican` for a pelican, every live crowd agent's grouped by
## `crowd` (a walker) or `traffic` (a car), and the baby's own running/alley share under `self` —
## all over the same `ExcitementHalo.WINDOW` the halo itself reads. Only positive shares are kept,
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
			var points := instance.landed()
			if points > 0.0:
				var name := instance.logged_name()
				by_group[name] = float(by_group.get(name, 0.0)) + points
	if city and city.crowd:
		for agent: CrowdAgent in city.crowd.agents():
			var points := agent.landed()
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
