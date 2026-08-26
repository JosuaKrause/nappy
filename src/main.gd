extends Node2D
## Boot scene. Replaced by the real world + HUD in M1/M2; for now it verifies that the
## autoloads load and the balance table is self-consistent.

@onready var _status: Label = $CanvasLayer/Status

func _ready() -> void:
	GameState.start_run()
	var lines := [
		"NAPPY",
		"",
		"seed        %d" % GameState.run_seed,
		"day         %d of %d  (act %d)" % [
			GameState.day, Tuning.RUN_LENGTH_DAYS, GameState.current_act()],
		"nerves      %d" % GameState.nerves,
		"day length  %.0fs" % Tuning.day_length(GameState.day),
		"",
		"autoloads OK - see docs/TODO.md for the next milestone",
	]
	_status.text = "\n".join(lines)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().quit()
