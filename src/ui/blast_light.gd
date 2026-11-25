class_name BlastLight
extends Node
## **The light of the bombs on the escape city's streets**: the sky over the city lit by a flash as
## each explosion goes off, fainter ones between for bombs further away (`FlashRhythm`), and her
## view shaken a little by an explosion near enough to be loud where she stands
## (`Stroller.shake_the_view()`) *(minty-lemur #785)*. Built by `main` for the escape city alone;
## the building shows its bangs in its windows (`InteriorScene`).
##
## **It lights the world, never the screen's furniture**: it lifts the city's own light toward the
## blast's (`CityDressing.light_the_sky()`), the way a hallway of the building lifts while its
## windows flash, so the HUD, the screen-edge badges and the controls, drawn on layers of their own
## over the world, keep exactly their look, and no danger is hidden by a flash.
##
## Handed the city whose sky it lights and her, never fetching either; told by `main` of every
## event that goes off (`see_it_go_off()`, from `EventBus.event_activated`), and asks the event
## whether the sky lights up for it (`EventInstance.flashes_as_it_goes_off()`), never its row.

var _rhythm := FlashRhythm.new()
var _sky: CityDressing = null
var _player: Stroller = null

## Hands it the city whose sky it lights.
func use_the_sky(sky: CityDressing) -> void:
	_sky = sky

## Hands it her: where an explosion is heard from, and whose view it shakes.
func use_player(player: Stroller) -> void:
	_player = player

## Starts the far flashes from `seed`, on every start of the city's walk (`FlashRhythm`).
func start_the_night(seed: int) -> void:
	_rhythm.start_the_night(seed)

## **Something went off** (`EventBus.event_activated`): an event the sky lights up for flashes, and
## shakes her view by the share of its full strength its field lands on her, nothing beyond its
## reach (`EventInstance.field_at()`).
func see_it_go_off(event: Node2D) -> void:
	var instance := event as EventInstance
	if instance == null or not instance.flashes_as_it_goes_off():
		return
	_rhythm.flash_for_a_bang()
	if _player != null and instance.peak() > 0.0:
		var heard := instance.field_at(_player.global_position, -1.0, Vector2.INF)
		_player.shake_the_view(heard / instance.peak())

## Counted on the physics tick, as everything that keeps the game's time does, so it freezes
## behind a pause screen.
func _physics_process(delta: float) -> void:
	_rhythm.step(delta)
	if _sky != null:
		_sky.light_the_sky(_rhythm.light())
