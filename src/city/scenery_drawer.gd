class_name SceneryDrawer
extends RefCounted
## What a retained batch of scenery pictures (`SceneryLayer`) and the street's flat decals
## (`CityDecals`) lay their pictures through: one `draw()` call per picture, told which canvas,
## which texture, the rectangle it fills and the part of the texture drawn into it. The city builds
## one and hands it to its decals (`CityDecals.drawer`), and through its roof drawer
## (`RoofDrawer`) to every vent's turning rotor; an event's drawer (`EventDrawer`) holds one of its
## own and hands it to the scenery of every crash and burst main it builds (`EventScenery.draw_through()`).
## Each owner hands it on to the layers it makes (`SceneryLayer.drawer`).
##
## The layer decides which texture stands where and when (the alternate frame of a rotor or a
## splash, a slice's part of a wide scene, a chunk's litter and tree beds); this decides how a
## texture is laid on the canvas. Kept apart so each is tested apart: a test hands an owner a drawer
## that records what it is told to lay instead of laying it, and checks the textures a layer stood,
## without reading what the layer holds. It holds nothing, so one serves every layer, and a draw
## makes no allocation of its own.

## Lays `texture` on `canvas` into `rect`, in `canvas`'s own space. `source`, when it has an area,
## is the part of the texture drawn into `rect`, in the texture's own pixels; an empty rect draws the
## whole texture.
func draw(canvas: CanvasItem, texture: Texture2D, rect: Rect2, source: Rect2) -> void:
	if source.has_area():
		canvas.draw_texture_rect_region(texture, rect, source)
	else:
		canvas.draw_texture_rect(texture, rect, false)
