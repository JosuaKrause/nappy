extends Node2D
## Reproducible native-scale review of generated networks on manually arranged runtime roofs.
##
## The building, roof tiles, facade, sidewalk and road all use their runtime atlas bindings. The
## six building lots are arranged manually; their network and equipment layouts use the same
## seeded placement as the city. No seed search or gameplay distribution claim is involved.

const OUTPUT := "res://docs/evidence/roof-networks-2026-10-03/roof-networks.png"

var _buildings := Node2D.new()
var _entities := Node2D.new()

func _enter_tree() -> void:
	AtlasLibrary.acquire(&"ground")

func _exit_tree() -> void:
	AtlasLibrary.release(&"ground")

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("7f8580"))
	_buildings.name = "Buildings"
	_entities.name = "Entities"
	_entities.y_sort_enabled = true
	add_child(_buildings)
	add_child(_entities)

	for index in 6:
		var building := Building.new()
		building.name = "ReviewRoof%d" % index
		building.position = Vector2(224 + (index % 3) * 416, 336 + (index / 3) * 352)
		building.footprint = Vector2(320 - (index % 3) * 32, 256)
		building.height = 64
		building.variant = index
		building.district = GameEnums.BlockPurpose.INDUSTRIAL
		building.roof_object_parent = _entities
		_buildings.add_child(building)
	var label := Label.new()
	label.text = "MANUAL ROOF ARRANGEMENT · GENERATED NETWORKS AND EQUIPMENT · NATIVE 1×"
	label.position = Vector2(24, 16)
	add_child(label)

	queue_redraw()
	await AutoScreenshot.drawn_frame(get_tree())
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(OUTPUT)
	if error != OK:
		push_error("roof context preview could not write %s: %s" % [OUTPUT, error_string(error)])
		get_tree().quit(1)
		return
	print("roof context preview wrote %s" % OUTPUT)
	get_tree().quit()

func _draw() -> void:
	var sidewalk := AtlasLibrary.region(&"tiles/layers/sidewalk_base")
	var road := AtlasLibrary.region(&"tiles/layers/asphalt_base")
	for x in range(0, 1280, 32):
		for y in range(64, 720, 32):
			var street := y >= 368 and y < 400 or x >= 384 and x < 480 or x >= 800 and x < 896
			draw_texture(road if street else sidewalk, Vector2(x, y))
