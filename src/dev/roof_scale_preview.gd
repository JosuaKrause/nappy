extends Node2D
## Native-scale equipment comparison, manually arranged over runtime roof and street textures.

const OUTPUT := "res://docs/evidence/roof-equipment-scale-2026-10-03/roof-scale.png"
const EQUIPMENT: Array[StringName] = [
	Building.SERVICE_BULKHEAD, Building.ENTRANCE_DOOR, Building.WATER_TANK,
	Building.HVAC_A, Building.HVAC_B, Building.DUCT_RUN,
	Building.VENT_STACK, Building.VENT_HOUSING, Building.EXHAUST_FAN,
	Building.PIPE_MANIFOLD, Building.SKYLIGHT_A, Building.SKYLIGHT_B,
]
const LABELS := ["Access room", "Regular door reference", "Water tank", "HVAC", "Condenser",
	"Duct reference", "Vent stacks", "Industrial fan", "Exhaust fan", "Pipe manifold",
	"Long skylight", "Pyramid skylight"]

func _ready() -> void:
	AtlasLibrary.acquire(&"ground")
	RenderingServer.set_default_clear_color(Color("7f8580"))
	var buildings := Node2D.new()
	add_child(buildings)
	var entities := Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	var building := Building.new()
	building.position = Vector2(640, 576)
	building.footprint = Vector2(1152, 448)
	building.height = 64
	building.variant = 4
	building.district = GameEnums.BlockPurpose.BIG_BUILDING
	building.roof_object_parent = entities
	buildings.add_child(building)
	for index in EQUIPMENT.size():
		var foot := Vector2(180 + (index % 6) * 184, 300 + (index / 6) * 144)
		var object := Building.RoofObject.new()
		object.texture_key = EQUIPMENT[index]
		object.position = foot
		entities.add_child(object)
		if EQUIPMENT[index] == Building.VENT_HOUSING:
			object.add_rotor(false)
		var label := Label.new()
		label.text = LABELS[index]
		label.add_theme_font_size_override("font_size", 14)
		label.position = foot + Vector2(-76, 12)
		add_child(label)
	var heading := Label.new()
	heading.text = "MANUAL EQUIPMENT COMPARISON · NATIVE 1× · REGULAR DOOR AS SCALE REFERENCE"
	heading.position = Vector2(32, 36)
	add_child(heading)
	queue_redraw()
	await AutoScreenshot.drawn_frame(get_tree())
	var error := get_viewport().get_texture().get_image().save_png(OUTPUT)
	if error != OK:
		push_error("roof scale preview could not write %s: %s" % [OUTPUT, error_string(error)])
		get_tree().quit(1)
		return
	print("roof scale preview wrote %s" % OUTPUT)
	get_tree().quit()

func _exit_tree() -> void:
	AtlasLibrary.release(&"ground")

func _draw() -> void:
	var sidewalk := AtlasLibrary.region(&"tiles/layers/sidewalk_base")
	var road := AtlasLibrary.region(&"tiles/layers/asphalt_base")
	for x in range(0, 1280, 32):
		for y in range(576, 640, 32):
			draw_texture(sidewalk, Vector2(x, y))
		for y in range(640, 720, 32):
			draw_texture(road, Vector2(x, y))
