class_name PauseScreen
extends CanvasLayer
## The pause. *(Playtest 07: "how can I pause the game?" — you could not.)*
##
## `Esc` quit the game outright for thirty-three milestones, which `CLAUDE.md` has listed under
## known-shaky ground for most of them. The only pause in the game was the between-days summary,
## which is a screen you cannot ask for.
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
signal quit_requested()

@onready var _root: Control = $Root

func _ready() -> void:
	# Above the world and above the HUD, and it must keep running while everything else stops.
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func is_open() -> bool:
	return visible

func open() -> void:
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

## `Esc` closes it and `Q` leaves the game. Handled here rather than in `main` so that the screen
## owns its own keys while it is up, and `main` only owns the one that opens it.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
		resumed.emit()
	elif event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_Q:
		get_viewport().set_input_as_handled()
		quit_requested.emit()
