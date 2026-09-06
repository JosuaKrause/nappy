class_name CityModels
extends Node3D
## Procedural diorama models for the orthographic street preview.
##
## This scene is deliberately separate from the playable 2D city. It gives the art direction a
## complete street corner to judge: overhanging roofs, readable entrances, narrow alleys, and
## wear that accumulates without changing any gameplay geometry.

const ROAD := Color("343943")
const ROAD_EDGE := Color("59606a")
const STONE := Color("b7aa95")
const STONE_DARK := Color("8c8174")
const GRASS := Color("647c55")
const GRASS_LIGHT := Color("7f9864")
const PLASTER := [Color("d2b99c"), Color("c3c7bb"), Color("d7c2a8"), Color("b7c0b2")]
const ROOF := [Color("765c55"), Color("8a6b58"), Color("5e6162"), Color("806d61")]
const TRIM := Color("ece0c8")
const WINDOW := Color("31454b")
const WINDOW_GLOW := Color("e5b96f")
const WOOD := Color("765447")
const CRACK := Color("443d3c")
const PAPER := Color("d7cba9")

@export var day14 := false

var _wear_root: Node3D
var _paper_nodes: Array[MeshInstance3D] = []
var _paper_origins: Array[Vector3] = []
var _paper_phases: Array[float] = []
var _time := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_world()
	set_day14(day14)

## Switches the art-only deterioration pass. The deterministic seed belongs to this preview and
## never touches the playable city's random stream.
func set_day14(enabled: bool) -> void:
	day14 = enabled
	if is_instance_valid(_wear_root):
		_wear_root.visible = enabled

func _process(delta: float) -> void:
	_time += delta
	for i in _paper_nodes.size():
		var paper: MeshInstance3D = _paper_nodes[i]
		var origin: Vector3 = _paper_origins[i]
		var phase: float = _paper_phases[i]
		var drift := Vector3(sin(_time * 0.72 + phase) * 0.9, 0.04 + sin(_time * 2.1 + phase) * 0.025,
			cos(_time * 0.55 + phase) * 0.65)
		paper.position = origin + drift
		paper.rotation.y = _time * 0.45 + phase
		paper.rotation.z = sin(_time * 1.2 + phase) * 0.18

func _build_world() -> void:
	var base_mat := _material(Color("958b7d"), 0.94)
	_box(self, "Ground", Vector3(46.0, 0.28, 46.0), Vector3(0.0, -0.18, 0.0), base_mat)

	var road_mat := _material(ROAD, 0.88)
	_box(self, "RoadEastWest", Vector3(46.0, 0.08, 7.2), Vector3(0.0, 0.02, 0.0), road_mat)
	_box(self, "RoadNorthSouth", Vector3(7.2, 0.09, 46.0), Vector3(0.0, 0.025, 0.0), road_mat)
	var road_edge_mat := _material(ROAD_EDGE, 0.9)
	for z in [-4.1, 4.1]:
		_box(self, "Kerb", Vector3(46.0, 0.18, 0.24), Vector3(0.0, 0.11, z), road_edge_mat)
	for x in [-4.1, 4.1]:
		_box(self, "Kerb", Vector3(0.24, 0.18, 46.0), Vector3(x, 0.11, 0.0), road_edge_mat)

	var pavement_mat := _material(STONE, 0.9)
	for z in [-5.0, 5.0]:
		_box(self, "Pavement", Vector3(46.0, 0.12, 1.55), Vector3(0.0, 0.1, z), pavement_mat)
	for x in [-5.0, 5.0]:
		_box(self, "Pavement", Vector3(1.55, 0.12, 46.0), Vector3(x, 0.1, 0.0), pavement_mat)

	# Small slabs make the alleys visibly traversable instead of filling the blocks with walls.
	var alley_mat := _material(STONE_DARK, 0.94)
	for x in [-12.0, 12.0]:
		_box(self, "Alley", Vector3(2.2, 0.08, 9.0), Vector3(x, 0.17, 9.2), alley_mat)
	_box(self, "Alley", Vector3(9.0, 0.08, 2.2), Vector3(-10.0, 0.17, -12.0), alley_mat)

	_building(Vector3(-12.0, 0.0, 12.0), Vector2(8.4, 8.0), 4.4, 0, true)
	_building(Vector3(12.0, 0.0, -12.0), Vector2(8.8, 8.0), 5.0, 1, false)
	_building(Vector3(-12.0, 0.0, -12.0), Vector2(8.0, 8.8), 3.8, 2, true)
	_build_park(Vector3(12.0, 0.0, 12.0))

	_wear_root = Node3D.new()
	_wear_root.name = "Day14Wear"
	add_child(_wear_root)
	_build_wear()

func _building(parent_position: Vector3, footprint: Vector2, height: float, variant: int,
		storefront: bool) -> void:
	var building := Node3D.new()
	building.name = "Building_%d" % variant
	building.position = parent_position
	add_child(building)
	var wall_mat := _material(PLASTER[variant], 0.88)
	var shadow_mat := _material(PLASTER[variant].darkened(0.22), 0.95)
	var roof_mat := _material(ROOF[variant], 0.9)
	var body_size := Vector3(footprint.x, height, footprint.y)
	_box(building, "PlasterBody", body_size, Vector3(0.0, height * 0.5, 0.0), wall_mat)
	_box(building, "Plinth", Vector3(footprint.x + 0.16, 0.26, footprint.y + 0.16),
		Vector3(0.0, 0.13, 0.0), shadow_mat)

	# Two shallow planes form a pitched roof with a half-tile overhang on every edge. The dark
	# fascia under them is the contact shadow that keeps the roof from reading as a floating lid.
	var roof_y := height + 0.38
	var roof_pitch := 0.34
	var half_width := footprint.x * 0.5 + 0.5
	var panel_width := half_width / cos(roof_pitch)
	_box(building, "RoofWest", Vector3(panel_width, 0.22, footprint.y + 1.0),
		Vector3(-footprint.x * 0.25, roof_y, 0.0), roof_mat, Vector3(0.0, 0.0, -roof_pitch))
	_box(building, "RoofEast", Vector3(panel_width, 0.22, footprint.y + 1.0),
		Vector3(footprint.x * 0.25, roof_y, 0.0), roof_mat, Vector3(0.0, 0.0, roof_pitch))
	_box(building, "RoofFascia", Vector3(footprint.x + 1.0, 0.22, 0.22),
		Vector3(0.0, height + 0.17, footprint.y * 0.5 + 0.5), shadow_mat)
	_box(building, "RoofFascia", Vector3(footprint.x + 1.0, 0.22, 0.22),
		Vector3(0.0, height + 0.17, -footprint.y * 0.5 - 0.5), shadow_mat)

	# Front windows have a reveal, sill, and trim rather than a painted rectangle.
	var window_mat := _material(WINDOW, 0.55)
	var glow_mat := _material(WINDOW_GLOW, 0.48, true)
	var frame_mat := _material(TRIM, 0.82)
	var windows := 2
	for col in windows:
		var wx := lerpf(-footprint.x * 0.28, footprint.x * 0.28, float(col) / float(windows - 1))
		_window(building, wx, height * 0.55, footprint.y * 0.5 + 0.06,
			window_mat if col == 0 else glow_mat, frame_mat)
		_window(building, wx, height * 0.55, -footprint.y * 0.5 - 0.06, window_mat, frame_mat)

	# A centered entrance gives every block a human-scale cue. Storefronts get a warm awning and a
	# lower reveal so the intersection has a distinct civic/commercial corner.
	var door_mat := _material(WOOD, 0.8)
	_box(building, "DoorReveal", Vector3(1.15, 1.9, 0.12), Vector3(0.0, 0.96, footprint.y * 0.5 + 0.07), shadow_mat)
	_box(building, "Door", Vector3(0.76, 1.62, 0.1), Vector3(0.0, 0.82, footprint.y * 0.5 + 0.14), door_mat)
	_box(building, "DoorLintel", Vector3(1.35, 0.16, 0.2), Vector3(0.0, 1.82, footprint.y * 0.5 + 0.15), frame_mat)
	if storefront:
		_box(building, "Shopfront", Vector3(footprint.x * 0.55, 1.0, 0.12),
			Vector3(0.0, 1.3, footprint.y * 0.5 + 0.11), glow_mat)
		_box(building, "Awning", Vector3(footprint.x * 0.68, 0.16, 0.9),
			Vector3(0.0, 2.0, footprint.y * 0.5 + 0.38), roof_mat, Vector3(-0.12, 0.0, 0.0))

	# Chimney stacks are capped and offset, avoiding a row of identical center cubes.
	var chimney_mat := _material(PLASTER[variant].darkened(0.3), 0.95)
	_box(building, "Chimney", Vector3(0.48, 0.9, 0.48),
		Vector3(footprint.x * 0.22, height + 0.86, -footprint.y * 0.18), chimney_mat)
	_box(building, "ChimneyCap", Vector3(0.7, 0.12, 0.7),
		Vector3(footprint.x * 0.22, height + 1.33, -footprint.y * 0.18), shadow_mat)

	# A restrained roof stipple catches the light as handmade texture without a shader or texture file.
	var stipple_mat := _material(ROOF[variant].lightened(0.18), 0.95)
	for dot in 5:
		var dx := lerpf(-footprint.x * 0.32, footprint.x * 0.32, float(dot) / 4.0)
		_box(building, "RoofStipple", Vector3(0.16, 0.03, 0.16),
			Vector3(dx, height + 0.57 + abs(dx) * 0.12, 0.1 * sin(float(dot))), stipple_mat)

func _window(parent: Node3D, x: float, y: float, z: float, glass: Material, frame: Material) -> void:
	_box(parent, "WindowReveal", Vector3(1.18, 1.25, 0.08), Vector3(x, y, z),
		_material(Color("605a55"), 0.92))
	_box(parent, "Glass", Vector3(0.84, 0.9, 0.1), Vector3(x, y, z + 0.07 if z > 0.0 else z - 0.07), glass)
	var outward := 0.13 if z > 0.0 else -0.13
	_box(parent, "Sill", Vector3(1.3, 0.12, 0.2), Vector3(x, y - 0.63, z + outward), frame)
	_box(parent, "Lintel", Vector3(1.3, 0.12, 0.2), Vector3(x, y + 0.63, z + outward), frame)
	_box(parent, "Mullion", Vector3(0.1, 1.0, 0.18), Vector3(x, y, z + outward), frame)

func _build_park(center: Vector3) -> void:
	var park := Node3D.new()
	park.name = "LushPark"
	park.position = center
	add_child(park)
	_box(park, "ParkGround", Vector3(10.0, 0.14, 10.0), Vector3(0.0, 0.2, 0.0), _material(GRASS, 0.96))
	var path_mat := _material(STONE_DARK.lightened(0.1), 0.92)
	_box(park, "ParkPathX", Vector3(10.0, 0.08, 0.9), Vector3(0.0, 0.31, 0.0), path_mat)
	_box(park, "ParkPathZ", Vector3(0.9, 0.08, 10.0), Vector3(0.0, 0.32, 0.0), path_mat)
	for point in [Vector3(-3.4, 0.0, -3.4), Vector3(3.4, 0.0, -3.2), Vector3(-3.3, 0.0, 3.2), Vector3(3.2, 0.0, 3.4)]:
		_tree(park, point)
	_box(park, "Bench", Vector3(1.8, 0.16, 0.42), Vector3(-1.7, 0.75, 1.4), _material(WOOD, 0.86))
	_box(park, "BenchLeg", Vector3(0.14, 0.5, 0.14), Vector3(-2.25, 0.45, 1.4), _material(WOOD, 0.86))
	_box(park, "BenchLeg", Vector3(0.14, 0.5, 0.14), Vector3(-1.15, 0.45, 1.4), _material(WOOD, 0.86))

func _tree(parent: Node3D, at: Vector3) -> void:
	var trunk_mat := _material(Color("6b5242"), 0.96)
	var leaf_mat := _material(GRASS_LIGHT, 0.94)
	_cylinder(parent, "Trunk", 0.18, 1.25, at + Vector3(0.0, 0.94, 0.0), trunk_mat)
	_sphere(parent, "Canopy", 1.1, at + Vector3(0.0, 2.15, 0.0), leaf_mat)
	_sphere(parent, "Canopy", 0.72, at + Vector3(0.55, 2.42, 0.16),
		_material(GRASS_LIGHT.lightened(0.07), 0.94))

func _build_wear() -> void:
	var wear_crack_mat := _material(CRACK, 0.98)
	var board_mat := _material(WOOD.lightened(0.08), 0.92)
	# Cracks are shallow dark planes on facades; boards are sparse so the whole city still feels lived in.
	for info in [
		[Vector3(-12.0, 0.0, 12.0), 4.4, 8.0, 0.0],
		[Vector3(12.0, 0.0, -12.0), 5.0, 8.0, 1.0],
		[Vector3(-12.0, 0.0, -12.0), 3.8, 8.8, 2.0],
	]:
		var root := Node3D.new()
		_wear_root.add_child(root)
		root.position = info[0]
		var h: float = info[1]
		var depth: float = info[2]
		_box(root, "Crack", Vector3(0.07, 1.15, 0.035), Vector3(-1.5, h * 0.56, depth * 0.5 + 0.08), wear_crack_mat,
			Vector3(0.0, 0.0, -0.24))
		_box(root, "Crack", Vector3(0.06, 0.7, 0.035), Vector3(-1.25, h * 0.3, depth * 0.5 + 0.09), wear_crack_mat,
			Vector3(0.0, 0.0, 0.38))
		if int(info[3]) != 2:
			_box(root, "BoardedWindow", Vector3(1.35, 0.13, 0.14), Vector3(1.25, h * 0.56, depth * 0.5 + 0.12), board_mat,
				Vector3(0.0, 0.0, -0.2))
			_box(root, "BoardedWindow", Vector3(1.35, 0.13, 0.14), Vector3(1.25, h * 0.56, depth * 0.5 + 0.14), board_mat,
				Vector3(0.0, 0.0, 0.2))

	var litter_mat := _material(PAPER, 0.99)
	var rng := RandomNumberGenerator.new()
	rng.seed = 14014
	for i in 9:
		var origin := Vector3(rng.randf_range(-17.0, 17.0), 0.34, rng.randf_range(-17.0, 17.0))
		if absf(origin.x) < 4.8 or absf(origin.z) < 4.8:
			origin.x += 5.6 if origin.x >= 0.0 else -5.6
		var paper := _box(_wear_root, "WindblownPaper", Vector3(0.38, 0.035, 0.24), origin, litter_mat)
		_paper_nodes.append(paper)
		_paper_origins.append(origin)
		_paper_phases.append(rng.randf_range(0.0, TAU))

func _material(colour: Color, roughness: float, emission: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	if emission:
		material.emission_enabled = true
		material.emission = colour
		material.emission_energy_multiplier = 0.35
	return material

func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, material: Material,
		rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = at
	mesh_instance.rotation = rotation
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mesh_instance)
	return mesh_instance

func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, at: Vector3,
		material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.1
	mesh.height = height
	mesh.radial_segments = 10
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = at
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mesh_instance)
	return mesh_instance

func _sphere(parent: Node3D, node_name: String, radius: float, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 1.7
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = at
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mesh_instance)
	return mesh_instance
