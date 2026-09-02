class_name PauseScreen
extends CanvasLayer
## The pause, and the only one a player can ask for — the between-days summary stops the tree too,
## but nobody chooses when it appears.
##
## It reuses the machinery `main` already built rather than inventing a second kind of paused: the
## tree's own `paused` flag, and `main._pauses_with_the_game()` deciding what that reaches. That
## matters more than it looks — the six-milestone bug M-something-or-other spent a milestone on
## was `process_mode` being inherited, so a pause that paused nothing ran for six milestones with
## the player still walking behind the screen that said the day was over. Anything added under
## `Main` needs that call, and this screen is deliberately **not** given it: a pause screen that
## pauses with the game cannot unpause it.
##
## Quitting keeps its key, one step further in. A run that is abandoned is still a run worth
## reading, so `Telemetry.end_run()` happens on the way out exactly as it did before.

signal resumed()
signal restart_requested()
signal quit_requested()

@onready var _root: Control = $Root
@onready var _dim: ColorRect = $Root/Dim
@onready var _standing: Label = $Root/Center/Lines/Standing
@onready var _hint: Label = $Root/Center/Lines/Hint

## Whether `Q` does anything on this platform. Read once from `QuitOption` rather than asked at
## each use site, so a test — never itself a web export — can set this and drive both shapes.
var _can_quit := QuitOption.available()

func _ready() -> void:
	# Above the world and above the HUD, and it must keep running while everything else stops.
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_refresh_hint()

## Baked into the scene is only the part that is always true; `q to quit` is added here, since
## whether it belongs depends on `_can_quit` rather than on anything the scene file can say.
## Its own function, rather than inline in `_ready()`, so a test can flip `_can_quit` and call
## this again to check the two platform shapes agree with `_unhandled_input`'s own gate.
func _refresh_hint() -> void:
	_hint.text = "space or esc to carry on     ·     r to start again"
	if _can_quit:
		_hint.text += "     ·     q to quit"

func is_open() -> bool:
	return visible

## Whether the tree was *already* paused when this opened — the between-days summary pauses it too.
##
## Putting back what was found rather than setting `false` is what lets the pause open **over** the
## summary. The alternative, and the first version, was refusing to open there at all, which reads
## as the key being broken on the one screen where somebody most wants it.
var _was_paused := false

## Where the run stands, at the top and in the largest type after the title.
##
## Both numbers are in the HUD, which this screen covers — and the pause is exactly when somebody
## stops to ask *how far in am I and how much of this can I still get wrong*.
##
## Read at `open()` rather than kept in step with `EventBus`, because a screen that is only ever
## looked at while the game is stopped cannot go stale, and a listener that has to be kept correct
## across fourteen days is a listener that will not be.
func _show_where_the_run_stands() -> void:
	var nerves := GameState.nerves
	_standing.text = "Day %d of %d     ·     %s" % [GameState.day, Tuning.RUN_LENGTH_DAYS,
			"last nerve" if nerves == 1 else "%d nerves left" % nerves]

func open() -> void:
	visible = true
	_show_where_the_run_stands()
	_was_paused = get_tree().paused
	# Over the stopped city the dim is a scrim and the street behind it is worth seeing. Over
	# another screen — which is what an already-paused tree means — it is two paragraphs of
	# different text in the same place, so it covers instead.
	_dim.color.a = 1.0 if _was_paused else DIM_OVER_THE_CITY
	get_tree().paused = true

const DIM_OVER_THE_CITY := 0.78

func close() -> void:
	visible = false
	get_tree().paused = _was_paused

## `Esc` **or `space`** closes it, `R` starts the whole run again and `Q` leaves the game —
## **except on the web**, where `QuitOption.available()` is false, `_ready()` never put "q to
## quit" in the hint, and the key is not handled either. Handled here rather than in `main` so
## that the screen owns its own keys while it is up, and `main` only owns the one that opens it.
##
## **`space` continues**, because it is the key the title screen and the between-days summary mean
## *carry on* with: a verb learned on two screens out of three and missing on the third is a verb
## the player has to unlearn. `Esc` keeps working too, because it is the key that opened this and a
## toggle should untoggle.
##
## **`R` restarts the run**, and it is the other half of the dead end the title screen closes. With
## the ending offering `Esc`, `Esc` opening this, and this offering `Esc` and `Q`, there are two
## screens and four keys and no way to play again. A run is also abandonable long before it has
## ended — a day gone wrong on a city you do not want to walk any more is exactly when somebody
## reaches for the pause — so the key belongs here and not only on the ending.
##
## It is deliberately not confirmed. Everything a run holds is a fourteen-day walk with no save in
## it, `R` is not next to `Esc`, and a confirmation on the one key that gets you out of a stuck game
## is a second way to be stuck.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		close()
		resumed.emit()
		return
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).keycode:
		KEY_R:
			get_viewport().set_input_as_handled()
			restart_requested.emit()
		KEY_Q:
			if _can_quit:
				get_viewport().set_input_as_handled()
				quit_requested.emit()
