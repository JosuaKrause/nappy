extends Node2D
## Reproducible in-engine review rig for the direct-PNG roof family.
##
## The building, roof tiles, facade, sidewalk and road all use their runtime atlas bindings. The
## eleven roof objects are arranged manually so one frame can review the whole family at actual
## game scale without depending on a random city seed to place every kind together.

const OUTPUT := "res://docs/evidence/m109-roof-context-2026-09-30/roof-context.png"
const EQUIPMENT: Array[StringName] = [
	Building.WATER_TANK,
	Building.HVAC_A,
	Building.HVAC_B,
	Building.SKYLIGHT_A,
	Building.SKYLIGHT_B,
	Building.VENT_STACK,
	Building.VENT_HOUSING,
	Building.SERVICE_BULKHEAD,
	Building.EXHAUST_FAN,
	Building.PIPE_MANIFOLD,
	Building.DUCT_RUN,
]
const FEET: Array[Vector2] = [
	Vector2(170, 330), Vector2(310, 330), Vector2(430, 330), Vector2(550, 330),
	Vector2(680, 330), Vector2(800, 330), Vector2(245, 480), Vector2(400, 480),
	Vector2(540, 480), Vector2(685, 480), Vector2(950, 480),
]

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

	var building := Building.new()
	building.name = "ReviewRoof"
	building.position = Vector2(640, 576)
	building.footprint = Vector2(1088, 384)
	building.height = 64
	building.variant = 4
	building.district = GameEnums.BlockPurpose.BIG_BUILDING
	building.roof_object_parent = _entities
	_buildings.add_child(building)

	for index in EQUIPMENT.size():
		var object := Building.RoofObject.new()
		object.name = "ReviewRoofObject%d" % index
		object.texture_key = EQUIPMENT[index]
		object.position = FEET[index]
		_entities.add_child(object)
		if EQUIPMENT[index] == Building.VENT_HOUSING:
			object.add_rotor(false)

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
		for y in range(576, 640, 32):
			draw_texture(sidewalk, Vector2(x, y))
		for y in range(640, 720, 32):
			draw_texture(road, Vector2(x, y))
