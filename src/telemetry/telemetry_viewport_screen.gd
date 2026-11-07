class_name TelemetryViewportScreen
extends TelemetryScreen
## The game's own viewport as the screen the run log photographs: nothing to draw headless, where
## the null display server draws no frame; otherwise the wait for a drawn frame every capture shares
## (`DrawnFrame.wait()`) and the viewport's texture once it is drawn.
##
## Built over a node that outlives the scene (`Telemetry`, an autoload): the wait and the viewport
## are that node's, so a scene reload in the middle of a capture leaves nothing freed to ask.

var _node: Node

func _init(node: Node) -> void:
	_node = node

## Overrides TelemetryScreen.can_draw.
func can_draw() -> bool:
	return DisplayServer.get_name() != "headless"

## Overrides TelemetryScreen.drawn.
func drawn() -> void:
	await DrawnFrame.wait(_node.get_tree())

## Overrides TelemetryScreen.picture.
func picture() -> Image:
	var viewport := _node.get_viewport()
	return viewport.get_texture().get_image() if viewport else null
