class_name SaveIndicator
extends CanvasLayer
## The small symbol that shows while a save is being kept and for a moment after — see
## docs/MECHANICS.md, "Saving and resuming". Saving itself is silent: there is no save button and
## no screen of its own, so this is the only thing that ever tells the player a save happened, or
## that it could not be kept.
##
## **Every change in the save state shows it, from the moment the change starts.** *(cozy-pelican,
## 2026-10-02: "okay always show it. but show it for at least a second"; "every change in the save
## state needs to show the symbol".)* **`GameSave` announces every change on `EventBus` and this
## node is the only one that listens**: a write raises it through `EventBus.save_written`, deleting
## the save file through `EventBus.save_deleted`, and the browser's later answer to either arrives
## on `EventBus.save_write_settled` or `EventBus.save_deletion_settled`. Nothing is relayed by
## `main`: the deletion a run's end makes comes from `GameState`, an autoload with no way to reach
## `main`, and a web save's answer may come after a scene reload has freed the `main` that saved,
## where a callable bound to it would be dropped and the symbol would stay fully shown for good. So
## one place decides when the symbol begins and is answered, and a change begins it exactly once.
## Every change carries its operation id from `GameSave`, on its announcement and on its answer, so
## an answer settles the change it belongs to and nothing else. `begin()` raises it, and it is fully
## shown for at least `MIN_SHOWN_SECONDS`, counted from when it appears, and for as long as **any**
## change it began is still unanswered, so nothing still being written looks finished —
## `settle()` answers one, on the web only once the browser has said whether IndexedDB kept it, see
## `GameSave.write()` and `GameSave.clear()` — and then fades over `FADE_SECONDS`. There is no hold
## after the answer and no delay before the symbol shows.
##
## **A change that was not kept shows `art/ui/save_unavailable.svg` instead,** the same disk struck
## through, fully for at least `MIN_STRUCK_SECONDS` counted from the moment it became struck, however
## fast the failure came back, and then the same fade. *(cozy-pelican: "if it fails it show for at
## least 10s".)* **Only the newest change decides the picture.** *(golden-otter, 2026-10-02: "if a
## new save succeeds it doesn't really matter if an old save failed. only the latest save action
## matters".)* The change begun last — the largest operation id begun — strikes the picture when it
## is not kept and clears the strike when it is; an older change's answer, in whichever order it
## arrives, changes neither. An answer to a change this symbol never began is ignored.
##
## Its own `CanvasLayer` above every screen, rather than a node added to the pause screen, the day
## summary and the HUD separately — "on whatever screen is up" is exactly the property a
## screen-specific node cannot have without three copies of it. `process_mode = PROCESS_MODE_ALWAYS`,
## the same as `main` itself, because a save made as the tree pauses (the moment a day's own
## summary appears) still has to fade on the clock rather than freeze mid-fade until the tree
## resumes.
##
## **It outlives the scene reloads a run makes.** The held restart deletes the save and frees `main`,
## and a symbol freed with it would never show the deletion, or show it only until the reload.
## `outlive_the_scene()` hands it to the scene tree's root, which a reload leaves alone; the
## `main` that boots next takes it back with `carried()` instead of building a second, so one
## symbol keeps its clocks and its picture across the reload and settles from the browser's answer
## on the freshly booted screen. The day-14 hand-over to the escape reloads the scene the same way
## and carries the symbol the same way (`main._reload_the_scene()` is the one place either reload
## happens). Its own `EventBus` connections, not a callable bound to `main`, are what carry the
## answer there, so nothing it is told can name a freed object — a save that was still pending when
## the scene reloaded, a day's summary retried or day 14's own save at the hand-over, is answered
## all the same.
##
## Built by `main._ready()` — before a resumed run's own charge can end the run and delete the
## save — and by `main._ready_escape()` for a run's own escape. The finale is reached in ordinary
## play (a won day 14 with every task complete hands the run over to it, see
## `main._hands_over_to_the_escape()`) and each of its section briefs writes the save, so that
## escape draws the symbol too. Not built under the `--start-escape` dev flag, where
## `GameSave.uses_save()` refuses every read, write and deletion and there is nothing to show.

## The least time the symbol is fully shown, counted from when it appears — long enough to be
## noticed once — and how long it then takes to fade. `MIN_STRUCK_SECONDS` is the same minimum for
## a struck symbol, counted from the moment it became struck, so a flush that took 5s to fail still
## has its struck picture up for the full 10s rather than only what is left of it. Three constants
## rather than one "how long" figure because "does it fade too fast", "does it stay up too long"
## and "does a failure stay up long enough" are three different questions.
const MIN_SHOWN_SECONDS := 1.0
const MIN_STRUCK_SECONDS := 10.0
const FADE_SECONDS := 1.5

## The fade's own peak alpha, once fully shown — the same figure `Palette.CHALK_DONE.a` carried
## back when this modulate also tinted the icon green. `art/ui/save.svg` now carries its own
## blue case, silver-gray shutter and paper label (PLAYTEST-95: "make it bluish and the metal
## parts should be silver/gray"), so this modulate only ever multiplies alpha: a colour here would
## multiply into the icon's own hues and turn the blue case back toward green-gray, which is the
## bug a shared tint constant would reintroduce.
const _PEAK_ALPHA := 0.9

## The name every symbol is given, and what `carried()` looks for on the tree's root.
const _NODE_NAME := "SaveIndicator"

## Above the title screen's own 95 (`TitleScreen.layer`), so a write mid-boot still shows through
## it rather than being hidden the moment the title opens over a fresh day 1.
const _LAYER := 100

## Bottom-right of the 1280x720 design box: clear of `TouchControls.PAUSE_CENTRE` (top-right) and
## the HUD's `Meters` column (bottom-left, or top-left once `_reposition_meters_for_touch()` moves
## it) — the two corners already claimed.
const _MARGIN := 24.0
const _SIZE := 48.0

## Region names on the `ui` atlas group; `_enter_tree()`/`_exit_tree()` acquire and release it.
## `_ICON_UNAVAILABLE` is the same disk struck through (`art/ui/save_unavailable.svg`), shown in
## place of `_ICON` when a save was not kept — a second picture rather than a strike drawn over the
## first, since a picture is an asset, never code (the **cues** skill).
const _ICON := &"ui/save"
const _ICON_UNAVAILABLE := &"ui/save_unavailable"

## The symbol's timeline apart from the node that draws it, so a test can drive every state
## without a tree, an atlas or a frame. Clocks move only through `advance()`.
##
## Three phases: hidden; fully shown, which lasts until nothing is pending and both minimums have
## run out; and fading. A `begin()` while fading or hidden brings the symbol back to full and
## restarts the `MIN_SHOWN_SECONDS` clock; a `begin()` while it is already fully shown does not,
## since the symbol has been up since an earlier moment.
class Showing extends RefCounted:
	enum Phase { HIDDEN, FULL, FADING }

	## How many changes are begun and not yet settled. While any is out the symbol is fully shown,
	## however long the minimums ran out ago — the newest or an older one alike, so nothing still
	## being written looks finished.
	var pending: int:
		get:
			return _unanswered.size()
	## Every `begin()` this timeline has been given, counted, so a test can tell one change begun
	## once from one begun twice — which the pending count alone cannot, once both are answered.
	var begun := 0
	## Whether the picture is the struck one. Set when the newest change begun is not kept, cleared
	## when it is kept, and when the symbol has faded out. `begin()` never clears it: a new change
	## still unanswered does not hide a failure already known, and only its own answer decides.
	var struck := false

	var _phase := Phase.HIDDEN
	## The changes begun and not yet settled, by operation id.
	var _unanswered: Dictionary = {}
	## The operation id of the newest change begun — the largest, since `GameSave` hands ids out in
	## increasing order — whose answer alone decides the picture.
	var _newest := 0
	## Seconds left of `MIN_SHOWN_SECONDS`, from when the symbol appeared.
	var _shown_left := 0.0
	## Seconds left of `MIN_STRUCK_SECONDS`, from the strike. Only counts while `struck`.
	var _struck_left := 0.0
	## Seconds left of the fade.
	var _fade_left := 0.0

	func begin(operation: int) -> void:
		begun += 1
		_unanswered[operation] = true
		_newest = maxi(_newest, operation)
		if _phase != Phase.FULL:
			_phase = Phase.FULL
			_shown_left = MIN_SHOWN_SECONDS

	## Answers the change `operation` names. An answer to a change not begun here, or already
	## answered, is ignored rather than counted against another: it may belong to a change announced
	## before a scene reload, to a symbol that did not survive it. Only the newest change's answer
	## moves the strike; an older one's only stops it being pending.
	func settle(operation: int, kept: bool) -> void:
		if not _unanswered.has(operation):
			return
		_unanswered.erase(operation)
		if operation == _newest:
			struck = not kept
			_struck_left = 0.0 if kept else MIN_STRUCK_SECONDS
		_start_fade_if_done()

	func advance(delta: float) -> void:
		match _phase:
			Phase.FULL:
				var owed := _owed()
				if pending > 0 or delta < owed:
					_shown_left = maxf(_shown_left - delta, 0.0)
					_struck_left = maxf(_struck_left - delta, 0.0)
					return
				# The minimums ran out inside this step: what is left of it already fades.
				_shown_left = 0.0
				_struck_left = 0.0
				_phase = Phase.FADING
				_fade_left = FADE_SECONDS
				_fade(delta - owed)
			Phase.FADING:
				_fade(delta)

	## How much of the symbol shows, from 0 to 1, before `_PEAK_ALPHA` scales it.
	func alpha() -> float:
		match _phase:
			Phase.FULL:
				return 1.0
			Phase.FADING:
				return _fade_left / FADE_SECONDS
		return 0.0

	func is_idle() -> bool:
		return _phase == Phase.HIDDEN

	## Seconds the symbol still owes of being fully shown, not counting any pending save.
	func _owed() -> float:
		return maxf(_shown_left, _struck_left if struck else 0.0)

	func _start_fade_if_done() -> void:
		if _phase == Phase.FULL and pending == 0 and _owed() <= 0.0:
			_phase = Phase.FADING
			_fade_left = FADE_SECONDS

	func _fade(delta: float) -> void:
		_fade_left -= delta
		if _fade_left <= 0.0:
			_phase = Phase.HIDDEN
			_fade_left = 0.0
			struck = false

var _icon_rect: TextureRect
var _plain_texture: Texture2D
var _struck_texture: Texture2D
var _showing := Showing.new()

func _init() -> void:
	name = _NODE_NAME
	layer = _LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS

func _enter_tree() -> void:
	AtlasLibrary.acquire(&"ui")

func _exit_tree() -> void:
	AtlasLibrary.release(&"ui")

func _ready() -> void:
	# For the life of the node, which is the process once `outlive_the_scene()` has run: a signal
	# disconnects on its own when its object is freed, so a symbol a test frees listens to nothing.
	EventBus.save_written.connect(_on_save_changed)
	EventBus.save_write_settled.connect(settle)
	EventBus.save_deleted.connect(_on_save_changed)
	EventBus.save_deletion_settled.connect(settle)
	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# Fixed to the 1280x720 box every screen is authored against, the same as every other rotating
	# layer's own root — see `ScreenOrientation.pin_to_design_box()`'s own doc.
	ScreenOrientation.pin_to_design_box(root)
	_icon_rect = TextureRect.new()
	_icon_rect.name = "Icon"
	_plain_texture = AtlasLibrary.region(_ICON)
	_struck_texture = AtlasLibrary.region(_ICON_UNAVAILABLE)
	_icon_rect.texture = _plain_texture
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon_rect.anchor_left = 1.0
	_icon_rect.anchor_top = 1.0
	_icon_rect.anchor_right = 1.0
	_icon_rect.anchor_bottom = 1.0
	_icon_rect.offset_left = -_MARGIN - _SIZE
	_icon_rect.offset_top = -_MARGIN - _SIZE
	_icon_rect.offset_right = -_MARGIN
	_icon_rect.offset_bottom = -_MARGIN
	_icon_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	root.add_child(_icon_rect)

## Called from `_on_save_changed()` the moment change `operation` starts — never for a run
## `GameSave` refuses (a dev flag, a headless run, or one already ended, which announce nothing), so
## the symbol is drawn on exactly the runs that save at all. Fully shown from here until every change
## begun is settled and for at least `MIN_SHOWN_SECONDS`, even mid-fade; a symbol already fully
## shown keeps its own clock.
func begin(operation: int) -> void:
	_showing.begin(operation)
	_apply()

## Answers the `begin()` with the same `operation`: `kept` is whether the change was confirmed.
## Struck through if it is the newest change begun and was not kept, plain if it is the newest and
## was; an older change's answer leaves the picture as it is. The fade starts once every change
## begun is answered and the minimums have run out.
func settle(operation: int, kept: bool) -> void:
	_showing.settle(operation, kept)
	_apply()

## `EventBus.save_written` and `EventBus.save_deleted`: the save was written, or its file was
## deleted, as change `operation`. `result` is a `GameSave.Result` as `int` — `PENDING` waits for
## `EventBus.save_write_settled` or `EventBus.save_deletion_settled` with the same id, anything else
## is the answer already, and is answered at once the way a desktop write is.
func _on_save_changed(operation: int, result: int) -> void:
	begin(operation)
	if result != GameSave.Result.PENDING:
		settle(operation, result == GameSave.Result.CONFIRMED)

## Whether the symbol is up at all — fully shown or fading.
func is_showing() -> bool:
	return not _showing.is_idle()

## Hands the symbol to the scene tree's root, so the scene reload the held restart or the day-14
## hand-over makes does not free it — see the class doc. Does nothing once it is already there, or
## off the tree.
func outlive_the_scene() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var home := _home(tree)
	if get_parent() != home:
		reparent(home, false)

## The symbol an earlier `main` handed to the tree's root with `outlive_the_scene()`, or `null`
## when none did. A `main` boots into it rather than building a second one.
static func carried(tree: SceneTree) -> SaveIndicator:
	if tree == null:
		return null
	return _home(tree).get_node_or_null(NodePath(_NODE_NAME)) as SaveIndicator

## Where a symbol that outlives its scene lives: the tree's root, which a scene reload leaves alone.
## `_home_override` is the seam a test points at a plain node instead, since a suite runs while the
## root is still busy adding the runner and cannot take a child; `null`, the default, answers
## normally, and a test sets it back when done.
static var _home_override: Node = null

static func _home(tree: SceneTree) -> Node:
	return _home_override if _home_override != null else tree.root

func _process(delta: float) -> void:
	if _showing.is_idle():
		return
	_showing.advance(delta)
	_apply()

func _apply() -> void:
	if not _icon_rect:
		return
	_icon_rect.modulate = Color(1.0, 1.0, 1.0, _PEAK_ALPHA * _showing.alpha())
	var texture := _struck_texture if _showing.struck else _plain_texture
	if _icon_rect.texture != texture:
		_icon_rect.texture = texture

## Whether the picture on screen is the struck-through one — what a test reads, since a headless
## run draws nothing to look at.
func shows_struck() -> bool:
	return _icon_rect != null and _icon_rect.texture == _struck_texture
