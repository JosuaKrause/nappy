extends RefCounted
## **`BlastLight`, the light of the bombs on the escape city's streets**, handed a city and her
## that each note what they are asked (the sky's level, the shake of her view), and told of an event
## going off the way `main` tells it (`see_it_go_off()`, connected to `EventBus.event_activated`).
## The events are the catalogue's own rows, created as the game creates a row set off under its
## warning (`EventInstance.arrive_from_its_warning()`, then aged past its telegraph). Real physics
## ticks pass for the light; when the sky lights and how brightly is `FlashRhythm`'s own suite.

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

func run(t: TestRunner) -> void:
	await _test_an_explosion_lights_the_sky_and_shakes_her_by_how_loud_it_is(t)
	_test_what_does_not_light_the_sky_does_nothing(t)

## An explosion going off 200px from her, inside its field's full-strength core, shakes her view
## at full strength; one 400px off, part way down its falloff, by less; one beyond its field's reach
## not at all. And the sky is lit once ticks pass.
func _test_an_explosion_lights_the_sky_and_shakes_her_by_how_loud_it_is(t: TestRunner) -> void:
	var sky := NotedSky.new()
	var her := NotedStroller.new()
	var light := BlastLight.new()
	light.use_the_sky(sky)
	light.use_player(her)
	t.add_child(light)
	var heard := EventCatalogue.FINALE_EXPLOSION_HEARD_WITHIN
	for away: float in [200.0, 400.0, heard + 80.0]:
		var bang := _gone_off("finale_explosion", Vector2(away, 0.0))
		light.see_it_go_off(bang)
		bang.free()
	t.check(her.shakes.size() == 3, "each explosion asks for a shake (%d)" % her.shakes.size())
	if her.shakes.size() == 3:
		t.check(is_equal_approx(her.shakes[0], 1.0), "at 200px, a full shake (%.2f)" % her.shakes[0])
		t.check(her.shakes[1] > 0.0 and her.shakes[1] < her.shakes[0],
				"at 400px, a smaller one (%.2f)" % her.shakes[1])
		t.check(her.shakes[2] == 0.0, "beyond its reach, none (%.2f)" % her.shakes[2])
	await PhysicsTicks.pass_ticks(t, 3)
	var brightest := 0.0
	for level in sky.levels:
		brightest = maxf(brightest, level)
	t.check(brightest > 0.0, "and the sky over the city is lit (%.2f)" % brightest)
	light.free()
	her.free()
	sky.free()

## A row the sky does not light up for (the cyclist) asks for no shake and lights nothing.
func _test_what_does_not_light_the_sky_does_nothing(t: TestRunner) -> void:
	var her := NotedStroller.new()
	var light := BlastLight.new()
	light.use_player(her)
	var rider := _gone_off("cyclist", Vector2(100.0, 0.0))
	t.check(not rider.flashes_as_it_goes_off(), "the cyclist does not light the sky")
	light.see_it_go_off(rider)
	t.check(her.shakes.is_empty(), "and shakes nothing")
	rider.free()
	light.free()
	her.free()

## The row `id` at `at`, created where its warning pointed and aged past its telegraph, as one set
## off under its warning comes: going off now.
func _gone_off(id: String, at: Vector2) -> EventInstance:
	var def := EventCatalogue.by_id(id)
	var instance := EventInstance.new()
	instance.setup(def, at)
	instance.arrive_from_its_warning()
	instance.restore(EventSave.aged(def.telegraphs_for()))
	return instance
