class_name FlockLook
extends EventLook
## The pigeons: every bird of the flock drawn where it is, on its own wingbeat.

func _draw_figure(canvas: CanvasItem) -> void:
	match event.def.look:
		EventDef.Look.BIRDS:
			_draw_birds(canvas)

## Every bird, drawn where it actually is.
##
## There is no `rise` term and no shared phase any more — see "the flock" above. What is left here
## is only the picture: each bird on its own beat, each with a shadow on the pavement under it that
## shrinks and fades as it climbs, and the whole flock painted back to front so a bird in front
## overlaps the one behind rather than fighting it for the same pixel every frame.
##
## The shadow is what sells the height, and it is the reason a bird 40px up does not simply read as
## a bird standing 40px further north.
func _draw_birds(canvas: CanvasItem) -> void:
	var order: Array[int] = []
	for i in event.birds().size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return event.birds()[a].at.y < event.birds()[b].at.y)
	for i in order:
		var bird := event.birds()[i]
		if bird.lift < BIRD_SHADOW_CEILING:
			# Smaller and fainter the higher it is, and gone by the time it is over the rooftops.
			var faded := 1.0 - bird.lift / BIRD_SHADOW_CEILING
			_draw_shadow(canvas, bird.at, 5.0 * faded)
		# Each bird holds its own sector — a flock is eleven bodies wheeling independently, not one
		# actor with one facing — through the same hold `_select_view()` gives the instance itself.
		bird.view_sector = EightDirection.update(bird.view_sector, bird.heading)
		var view: String = EventPictures.EIGHT_VIEW_BY_SECTOR[bird.view_sector]
		var mirror := EightDirection.is_mirrored(bird.view_sector)
		var wings: String = EventPictures.PIGEON_BY_VIEW[view] if sin(bird.phase) >= 0.0 \
				else EventPictures.PIGEON_DOWN_BY_VIEW[view]
		if bird.lift <= 0.0:
			# Standing. The upstroke is a bird in flight, and a pavement full of them is a flock
			# that has already gone — which is the thing the wait and the telegraph before it exist
			# to show her instead.
			wings = EventPictures.PIGEON_DOWN_BY_VIEW[view]
		Sprites.draw_standing(canvas, EventPictures.drawn(wings), bird.at - Vector2(0.0, bird.lift),
				Vector2.ZERO, mirror)

## How high a bird's shadow survives to. Roughly first-floor height: above it, there is nothing on
## the pavement to cast one onto that the player can see.
const BIRD_SHADOW_CEILING := 46.0
