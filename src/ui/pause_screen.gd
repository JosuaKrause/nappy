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
signal restart_requested()
signal quit_requested()

@onready var _root: Control = $Root
@onready var _dim: ColorRect = $Root/Dim
@onready var _standing: Label = $Root/Center/Lines/Standing

func _ready() -> void:
	# Above the world and above the HUD, and it must keep running while everything else stops.
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

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
## *(M39, playtest 10 finding 7: "in the pause screen the day and nerves should show prominently as
## well".)* Both numbers are in the HUD, behind a screen that covers the HUD — and the pause is
## exactly when somebody stops to ask *how far in am I and how much of this can I still get wrong*.
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

## `Esc` **or `space`** closes it, `R` starts the whole run again and `Q` leaves the game. Handled
## here rather than in `main` so that the screen owns its own keys while it is up, and `main` only
## owns the one that opens it.
##
## **`space` is M39.** *(Playtest 10, finding 6: "from pause space should also let you continue".)*
## It is the key the title screen and the between-days summary already mean *carry on* with, and the
## pause was the one screen in the game that did not take it — so the player learned a verb on two
## screens out of three and found it missing on the third. `Esc` keeps working, because it is also
## the key that opened this and a toggle should untoggle.
##
## **`R` is M38**, and it is the other half of the dead end the title screen fixes. *("The lost
## screen doesn't allow for restarting the game — you can just cycle between pause screen and loss
## screen at that point.")* The ending offered `Esc`, `Esc` opened this, and this offered `Esc` and
## `Q`: two screens, four keys, and no way to play again. A run is also abandonable long before it
## has ended — a day gone wrong on a city you do not want to walk any more is exactly when somebody
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
			get_viewport().set_input_as_handled()
			quit_requested.emit()
