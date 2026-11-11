class_name FlockLook
extends EventLook
## The pigeons: every bird of the flock drawn where it is, on its own wingbeat.

## Overrides EventLook._draw_figure.
func _draw_figure(canvas: CanvasItem) -> void:
	match _row.picture():
		EventDef.Look.BIRDS:
			_draw_birds(canvas)

## Every bird, drawn where it actually is.
##
## The birds' motion is the flock's (`EventFlock`); this is only the picture: each bird on its own
## beat, each with a shadow on the pavement under it that
## shrinks and fades as it climbs, and the whole flock painted back to front so a bird in front
## overlaps the one behind rather than fighting it for the same pixel every frame.
##
## The shadow is what sells the height, and it is the reason a bird 40px up does not simply read as
## a bird standing 40px further north.
func _draw_birds(canvas: CanvasItem) -> void:
	var birds := event.birds()
	_see_every_bird(birds)
	var order: Array[int] = []
	for i in birds.size():
		order.append(i)
	order.sort_custom(func(a: int,
			b: int) -> bool: return birds[a].at.y < birds[b].at.y)
	for i in order:
		var bird := birds[i]
		if bird.lift < BIRD_SHADOW_CEILING:
			# Smaller and fainter the higher it is, and gone by the time it is over the rooftops.
			var faded := 1.0 - bird.lift / BIRD_SHADOW_CEILING
			_draw_shadow(canvas, bird.at, 5.0 * faded)
		# Each bird holds its own sector — a flock is eleven bodies wheeling independently, not one
		# actor with one facing — through the same hold `select_view()` gives the instance itself.
		_held_sectors[i] = EightDirection.update(_held_sectors[i], bird.heading)
		var view: String = EventPictures.EIGHT_VIEW_BY_SECTOR[_held_sectors[i]]
		var mirror := EightDirection.is_mirrored(_held_sectors[i])
		var wings: String = EventPictures.PIGEON_BY_VIEW[view] if sin(bird.phase) >= 0.0 \
				else EventPictures.PIGEON_DOWN_BY_VIEW[view]
		if bird.lift <= 0.0:
			# Standing. The upstroke is a bird in flight, and a pavement full of them is a flock
			# that has already gone — which is the thing the wait and the telegraph before it exist
			# to show her instead.
			wings = EventPictures.PIGEON_DOWN_BY_VIEW[view]
		_drawer.stand(canvas, wings, bird.at - Vector2(0.0, bird.lift),
				Vector2.ZERO, mirror)

## The eight-view sector each bird is held at, parallel to the flock's birds: one per bird rather
## than the one sector the look holds for a single body (`_view_sector`), since a flock is eleven
## bodies wheeling independently. The look's own, as it is the only thing a sector is held for.
var _held_sectors: Array[int] = []

## Gives every bird the look has not drawn before its first held sector: the exact nearest one for
## where it faces, the same "no prior-view hold on a fresh placement" rule `face()` gives the
## instance itself (`EightDirection.nearest()`).
func _see_every_bird(birds: Array[EventFlock.Bird]) -> void:
	while _held_sectors.size() < birds.size():
		_held_sectors.append(EightDirection.nearest(birds[_held_sectors.size()].heading))

## How high a bird's shadow survives to. Roughly first-floor height: above it, there is nothing on
## the pavement to cast one onto that the player can see.
const BIRD_SHADOW_CEILING := 46.0
