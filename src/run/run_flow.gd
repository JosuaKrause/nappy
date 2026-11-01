class_name RunFlow
extends RefCounted
## The run's way through its screens: which screen stands in front of the walk (`mode`), and what
## that screen's continue leads to (`continued()`). `main` builds one per boot, tells it each time a
## screen comes up or a day ends, and carries out the `Step` its continue returns; the flow itself
## shows nothing, and builds a day only by having the `DayDirector` it is handed start it.
##
## **A scene recipe is a configuration of it** (`author()`, `scene`): an authored scene is one day,
## so every continue plays that scene again, a lost escape section is retried by the scene itself, a
## won last day hands over to nothing, its day is installed by the scene rather than planned from the
## run, its city is built on the scene's own map, the escape's city plans no finale of its own, and the
## HUD says none of the control lessons the scene has learned.
##
## It also announces the day being walked to the observers that draw it — the developer readout, the
## HUD's clock and the route rig — through `day_started` and `day_planned`, which carry the day's
## `DaySpec`, and a brief going up through `brief_opened`; `main` connects them.

## A day or a section is about to be built: `spec` is what it is. Before anything is placed.
signal day_started(spec: DaySpec)
## The day or section has been built and placed, and its shape announced on `EventBus.day_planned`.
## An authored scene's day is never planned, so it never sends this.
signal day_planned(spec: DaySpec)
## A brief has been raised (`open_brief()`) over `spec`, the day or section it leads into. The screen
## itself is shown right after, by `main`; a dev rig that has nobody to press the brief's continue
## answers it a frame later, through the screen's own input.
signal brief_opened(spec: DaySpec)

## The screen in front of the walk, or that there is none.
enum Mode {
	## The boot is building the run; no screen is up yet.
	BOOTING,
	## The title, over a day already built.
	TITLE,
	## A day brief over a day or section already built: a resumed day's, or a section's. Its continue
	## engages it.
	BRIEF,
	## She is walking a day or a section; no screen is up.
	WALKING,
	## An ordinary day's end: its continue starts the next attempt, the same day or the next one.
	DAY_OVER,
	## A lost day that spent a normal run's last nerve: its continue carries the run, back at its
	## checkpoint's dawn, into a fresh boot.
	BACK_TO_CHECKPOINT,
	## Day 14 won with every task done: its continue reloads the scene into the escape's building.
	INTO_ESCAPE,
	## A lost escape section: its continue tries the section again behind its brief.
	SECTION_LOST,
	## The summary of the day or section that ended the run: its continue shows the ending.
	RUN_OVER,
	## The ending: its continue goes back to the title, through the held restart's reload.
	ENDING,
	## The escape's last screen, the way out behind her: its continue goes back to the title.
	EPILOGUE,
	## A scene reload is on its way; nothing more happens on this boot.
	RELOADING,
}

## What a continue leads to, for `main` to carry out.
enum Step {
	## Nothing: no screen is up for the continue to answer.
	NONE,
	## Dismiss the brief and hand her the day already built.
	ENGAGE,
	## Dismiss the summary, start the next attempt and save it as under way.
	NEXT_DAY,
	## Dismiss the summary and carry the run into a fresh boot at its checkpoint.
	CARRY_TO_CHECKPOINT,
	## Dismiss the outcome screen, start the section again and raise its brief.
	RETRY_SECTION,
	## Raise the ending over the summary.
	SHOW_ENDING,
	## Throw the run away and go back to the title.
	RESTART_RUN,
	## Dismiss the screen and reload the scene: into the escape's building, or an authored scene
	## played again.
	RELOAD_SCENE,
	## A lost escape section of an authored scene: its own runtime retries it, or reloads it.
	RETRY_AUTHORED,
	## A lost escape section's outcome screen comes up.
	SHOW_OUTCOME,
}

## How this boot came to the run it plays.
enum Opening {
	## A run begun fresh.
	FRESH,
	## A run picked back up from the save.
	RESUMED,
	## A normal run carried on from its checkpoint by the continue of the day that sent it back.
	CARRIED_FROM_CHECKPOINT,
	## The escape, handed over by a won day 14 through a scene reload.
	ESCAPE_HANDED_OVER,
	## The escape, picked back up from a save closed inside one of its sections.
	ESCAPE_RESUMED,
	## The escape on its own, from `--start-escape`, with no run behind it.
	ESCAPE_BY_FLAG,
}

var mode := Mode.BOOTING
var opening := Opening.FRESH
## The day or section being walked; an ordinary day until one starts.
var spec := DaySpec.new()
## The authored scene (a scene recipe's playback) this boot plays, or null for the game's own run.
var scene: AuthoredScene
## Whether an authored scene is played rather than the game's own run.
var authored: bool:
	get:
		return scene != null

func _init(the_scene: AuthoredScene = null) -> void:
	scene = the_scene

## Configures the flow with the authored scene this boot plays, once it is built.
func author(the_scene: AuthoredScene) -> void:
	scene = the_scene

## Whether a run stands behind the escape this boot plays: its own ending, handed over or resumed,
## rather than the flag's walk, which settles nothing when she gets out.
func escape_from_a_run() -> bool:
	return opening == Opening.ESCAPE_HANDED_OVER or opening == Opening.ESCAPE_RESUMED

## Whether a won last day hands the run over to the escape. An authored scene's never does: its won
## day plays the scene again.
func escape_follows() -> bool:
	return not authored

## Whether the escape's city plans its own finale. An authored scene installs its own.
func plans_the_finale() -> bool:
	return not authored

## The map the city is built on when it is an authored scene's own, or null for the one the run's
## seed generates.
func authored_map() -> CityMap:
	return scene.city_map() if authored else null

## Whether the run starts after the ordinary control lessons have been learned: an authored scene
## that says so. The game's own run teaches them.
func lessons_learned() -> bool:
	return authored and scene.lessons_learned()

func in_the_title() -> bool:
	return mode == Mode.TITLE

## Whether the escape's brief or its last screen is up — the two screens Esc does not open over,
## since each stands in front of something that has not begun.
func escape_screen_waits() -> bool:
	return spec.section != DaySpec.Section.NONE \
			and (mode == Mode.BRIEF or mode == Mode.EPILOGUE)

# ------------------------------------------------------------------ the day ---

## A day or a section begins: `the_spec` is what is walked from here, and the observers hear it.
func begin(the_spec: DaySpec) -> void:
	spec = the_spec
	day_started.emit(the_spec)

## The day or section just begun has been built and placed.
func planned() -> void:
	day_planned.emit(spec)

## A day begins and `director` starts it: announced, built, and announced planned once placed. An
## authored scene's day is the director's `start_authored_day()`, begun and never planned. Returns
## the problems that kept an authored scene's setup from standing, empty when the day stands.
func start_day(director: DayDirector, the_spec: DaySpec) -> Array[String]:
	begin(the_spec)
	if authored:
		return director.start_authored_day(the_spec, scene)
	director.start_day(the_spec)
	planned()
	return []

# ----------------------------------------------------------- the screens ---

func open_title() -> void:
	mode = Mode.TITLE

func open_brief() -> void:
	mode = Mode.BRIEF
	brief_opened.emit(spec)

func engage() -> void:
	mode = Mode.WALKING

func show_ending() -> void:
	mode = Mode.ENDING

## An ordinary day has ended, as `DayDirector.finish_day()` settled it.
func day_ended(end: DayEnd) -> void:
	if end.hands_over_to_the_escape:
		mode = Mode.INTO_ESCAPE
	elif end.goes_back:
		mode = Mode.BACK_TO_CHECKPOINT
	elif end.run_over:
		mode = Mode.RUN_OVER
	else:
		mode = Mode.DAY_OVER

## A section of the escape was lost, and `run_over` says whether that ended the run. An authored
## scene's runtime takes the retry over; otherwise the outcome screen comes up.
func section_lost(run_over: bool) -> Step:
	if authored:
		return Step.RETRY_AUTHORED
	mode = Mode.RUN_OVER if run_over else Mode.SECTION_LOST
	return Step.SHOW_OUTCOME

## She got out of the city: the last screen of the escape.
func escape_won() -> void:
	mode = Mode.EPILOGUE

## The scene is being reloaded, whichever way the run came to it: the held restart, a step that
## reloads, or an authored scene that failed its own retry.
func reload() -> void:
	mode = Mode.RELOADING

## The continue of the screen raised in `raised_in`: the step it leads to, and the mode that step
## leaves the run in. **Answered by the mode the screen was raised in**, which `DaySummary` sends
## with its continue: a continue from a screen the run has already left, and a continue with no
## screen up, lead nowhere. `DaySummary` sends none of those (a tap's continue, sent two frames late,
## is dropped once its screen is gone), so this is the flow's own rule, not the guard against a tap
## and a key reaching one screen.
func continued(raised_in: Mode) -> Step:
	if raised_in != mode:
		return Step.NONE
	var step := _step_for(mode)
	match step:
		Step.ENGAGE, Step.NEXT_DAY:
			mode = Mode.WALKING
		Step.RETRY_SECTION:
			mode = Mode.BRIEF
		Step.SHOW_ENDING:
			mode = Mode.ENDING
		Step.CARRY_TO_CHECKPOINT, Step.RESTART_RUN, Step.RELOAD_SCENE:
			mode = Mode.RELOADING
	return step

func _step_for(current: Mode) -> Step:
	match current:
		Mode.BOOTING, Mode.TITLE, Mode.WALKING, Mode.RELOADING:
			return Step.NONE
	if authored:
		return Step.RELOAD_SCENE
	match current:
		Mode.BRIEF:
			return Step.ENGAGE
		Mode.DAY_OVER:
			return Step.NEXT_DAY
		Mode.BACK_TO_CHECKPOINT:
			return Step.CARRY_TO_CHECKPOINT
		Mode.INTO_ESCAPE:
			return Step.RELOAD_SCENE
		Mode.SECTION_LOST:
			return Step.RETRY_SECTION
		Mode.RUN_OVER:
			return Step.SHOW_ENDING
	return Step.RESTART_RUN
