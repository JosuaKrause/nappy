extends RefCounted
## **`BlastLight`, the light of the bombs on the escape city's streets**, handed a city and her
## that each note what they are asked (the sky's level, the shake of her view), and told of an event
## going off the way `main` tells it (`see_it_go_off()`, connected to `EventBus.event_activated`).
## The event is a fake answering only what the light asks of one: whether the sky lights up for it,
## and where it stands, so the case checks that the shake follows how near it is; how the share falls
## off with distance is `ViewShake`'s own suite's. Real physics ticks
## pass for the light; when the sky lights and how brightly is `FlashRhythm`'s own suite.

## The sky over a city: notes every level it is lit to.
class NotedSky extends CityDressing:
	var levels: Array[float] = []

	## Overrides CityDressing.light_the_sky.
	func light_the_sky(level: float) -> void:
		levels.append(level)

## Her: notes every shake of her view she is asked for.
class NotedStroller extends Stroller:
	var shakes: Array[float] = []

	## Overrides Stroller.shake_the_view.
	func shake_the_view(share: float) -> void:
		shakes.append(share)

## An event going off: whether the sky lights for it, as the case sets it.
class FakeBang extends EventInstance:
	var _lights_the_sky: bool

	func _init(flashes: bool) -> void:
		_lights_the_sky = flashes

	## Overrides EventInstance.flashes_as_it_goes_off.
	func flashes_as_it_goes_off() -> bool:
		return _lights_the_sky

func run(t: TestRunner) -> void:
	await _test_an_explosion_lights_the_sky_and_shakes_her_by_how_near_it_is(t)
	_test_what_does_not_light_the_sky_does_nothing(t)

## An explosion on top of her shakes her view at full strength; one at the distance explosions are
## set off at (`EventCatalogue.FINALE_EXPLOSION_SET_OFF_WITHIN`), further than its noise reaches,
## still shakes it, less; one beyond the shake's reach, not at all. And the sky is lit once ticks pass.
func _test_an_explosion_lights_the_sky_and_shakes_her_by_how_near_it_is(t: TestRunner) -> void:
	var sky := NotedSky.new()
	var her := NotedStroller.new()
	var light := BlastLight.new()
	light.use_the_sky(sky)
	light.use_player(her)
	t.add_child(light)
	var distances: Array[float] = [0.0, EventCatalogue.FINALE_EXPLOSION_SET_OFF_WITHIN,
			EventCatalogue.FINALE_EXPLOSION_FELT_WITHIN + 1.0]
	for distance in distances:
		var bang := FakeBang.new(true)
		bang.global_position = her.global_position + Vector2(distance, 0.0)
		light.see_it_go_off(bang)
		bang.free()
	t.check(her.shakes.size() == 3, "each explosion asks for a shake (%d)" % her.shakes.size())
	if her.shakes.size() == 3:
		t.check(is_equal_approx(her.shakes[0], 1.0), "on top of her, a full shake (%.2f)"
				% her.shakes[0])
		t.check(EventCatalogue.FINALE_EXPLOSION_SET_OFF_WITHIN > EventCatalogue.FINALE_EXPLOSION_HEARD_WITHIN
				and her.shakes[1] > 0.0 and her.shakes[1] < her.shakes[0],
				"set off beyond its noise, it still shakes her view, less (%.2f)" % her.shakes[1])
		t.check(her.shakes[2] == 0.0, "beyond the shake's reach, none (%.2f)" % her.shakes[2])
	await PhysicsTicks.pass_ticks(t, 3)
	var brightest := 0.0
	for level in sky.levels:
		brightest = maxf(brightest, level)
	t.check(brightest > 0.0, "and the sky over the city is lit (%.2f)" % brightest)
	light.free()
	her.free()
	sky.free()

## An event the sky does not light up for asks for no shake and lights nothing.
func _test_what_does_not_light_the_sky_does_nothing(t: TestRunner) -> void:
	var her := NotedStroller.new()
	var light := BlastLight.new()
	light.use_player(her)
	var rider := FakeBang.new(false)
	light.see_it_go_off(rider)
	t.check(her.shakes.is_empty(), "it shakes nothing")
	rider.free()
	light.free()
	her.free()
