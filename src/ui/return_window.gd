class_name ReturnWindow
extends Node
## The half second after the game gets focus back, during which every input is ignored, and the
## departures and returns that open it — the engine's focus notifications and, on the web, the
## page's own `visibilitychange`, `focus` and `blur`. The tap or click that brings the page back is
## also an event the game reads, and without the window it resumes the pause screen or starts the
## day from its brief before the player has seen either (inbox #534 in misty-toad).
##
## **`Viewport.set_disable_input(true)` is how the window is enforced**, not a mark in an `_input()`:
## a disabled viewport delivers nothing to any `_input()`, the GUI or `_unhandled_input()`, so
## `TouchControls._input()` (which no handler can pre-empt) and the pause and day-brief screens are
## all deaf together. It stops *events* only: `Input`'s held state still follows the keyboard.
##
## **Nothing can leave input off.** The end is read off the wall clock every frame (`_process()`,
## which runs under a pause, since this node inherits `main`'s `PROCESS_MODE_ALWAYS`), and leaving
## the tree and `setup()` clear it too, because the root viewport outlives a scene reload. Real OS
## time rather than accumulated `delta`, and a frame check rather than a timer: a `SceneTreeTimer`
## can fire before its time (its first frame's delta includes the time before it was made), which
## left input off for good.
##
## Losing focus is announced (`left_the_game`); what it opens is `main`'s to decide, since the
## screens are `main`'s.

## Focus went away: the window lost focus, the app was sent to the background, or the page went
## hidden or blurred.
signal left_the_game()

## How long every input is ignored after a return.
const IGNORED_MSEC := 500

## The `Time.get_ticks_msec()` reading at which the window ends, or `0` for no window.
var _ignored_until_msec := 0
## Whether the game has been left since the window last opened. **A return needs a departure:** the
## page's own first focus at load is not a return, and a player's first tap in the half second after
## the page loads must reach the game. Set by a departure, spent by the arming.
var _has_left_the_game := false
## The viewport whose input is switched off for the window; `setup()` sets it, a test sets its own.
var _viewport: Viewport = null
## `--no-focus-pause` (which `--screenshot` implies) and a rig's run (`RigLock.locked_out`) are
## never slowed by the window. Members, so a test can set either.
var _no_focus_pause := false
var _rig := false
## The page-side callback the web listeners call, held for the node's lifetime: a
## `JavaScriptObject` made by `create_callback()` stops answering once nothing holds it.
var _web_callback: JavaScriptObject = null

## Starts watching for departures and returns, with input on: the viewport the window switches,
## and whether this run is never slowed by it.
func setup(viewport: Viewport, no_focus_pause: bool, rig: bool) -> void:
	_viewport = viewport
	_no_focus_pause = no_focus_pause
	_rig = rig
	end(true)
	_viewport.set_disable_input(false)
	_listen_on_the_web()

## Whether the window is still running.
func ignoring_input() -> bool:
	return Time.get_ticks_msec() < _ignored_until_msec

func _process(_delta: float) -> void:
	end()

func _exit_tree() -> void:
	end(true)
	_stop_listening_on_the_web()

## `NOTIFICATION_APPLICATION_FOCUS_OUT` is the one this game has one window to lose: the OS giving
## focus to another application, which is Alt-Tabbing away, a browser tab going to the background
## or a click on another window. `NOTIFICATION_WM_WINDOW_FOCUS_OUT` is per `Window`, for a game with
## several windows of its own, which this one never builds. `NOTIFICATION_APPLICATION_PAUSED` is a
## phone sending the app away. Getting focus back (`_FOCUS_IN`, `_RESUMED`) opens the window.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_leave()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		_arm()

func _leave() -> void:
	_has_left_the_game = true
	left_the_game.emit()

## Opens the window on a return. A no-op without a departure first, which the arming spends, so a
## second trigger inside the window does nothing unless the game was left again in between; and a
## no-op for a rig or under `--no-focus-pause`.
func _arm() -> void:
	if not _has_left_the_game or _no_focus_pause or _rig or _viewport == null:
		return
	_has_left_the_game = false
	_ignored_until_msec = Time.get_ticks_msec() + IGNORED_MSEC
	_viewport.set_disable_input(true)

## Puts input back once the window has passed, or at once with `force`.
func end(force := false) -> void:
	if _ignored_until_msec == 0 or (not force and ignoring_input()):
		return
	_ignored_until_msec = 0
	if _viewport != null and is_instance_valid(_viewport):
		_viewport.set_disable_input(false)

## The web page is where returning was seen, and the engine's FOCUS_IN on a tab return is not
## confirmed there, so a second trigger comes straight from the browser. Whichever return arrives
## first opens the window; later ones inside it find the departure already spent. Web builds only.
func _listen_on_the_web() -> void:
	if not OS.has_feature("web") or _web_callback != null:
		return
	_web_callback = JavaScriptBridge.create_callback(_on_web_callback)
	var document := JavaScriptBridge.get_interface("document")
	var window := JavaScriptBridge.get_interface("window")
	document.addEventListener("visibilitychange", _web_callback)
	window.addEventListener("focus", _web_callback)
	window.addEventListener("blur", _web_callback)

## Removes what `_listen_on_the_web()` added, so a scene reload does not pile up listeners.
func _stop_listening_on_the_web() -> void:
	if _web_callback == null:
		return
	JavaScriptBridge.get_interface("document").removeEventListener("visibilitychange", _web_callback)
	JavaScriptBridge.get_interface("window").removeEventListener("focus", _web_callback)
	JavaScriptBridge.get_interface("window").removeEventListener("blur", _web_callback)
	_web_callback = null

func _on_web_callback(args: Array) -> void:
	var event: JavaScriptObject = args[0] if args.size() > 0 else null
	var kind := str(event.type) if event != null else ""
	on_web_event(kind, str(JavaScriptBridge.get_interface("document").visibilityState))

## The decision half of the web callback, with the browser's answers passed in so a test can drive
## it: a `blur`, or a `visibilitychange` to anything but "visible", is a departure; a `focus`, or a
## `visibilitychange` to "visible", is a return. A web departure opens no pause of its own — the
## engine's focus notification is what does — so it only marks the departure.
func on_web_event(kind: String, visibility: String) -> void:
	if kind == "blur" or (kind == "visibilitychange" and visibility != "visible"):
		_has_left_the_game = true
	elif kind == "focus" or kind == "visibilitychange":
		_arm()
