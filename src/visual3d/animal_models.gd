class_name AnimalModels extends RefCounted
## Builds the authored animal silhouettes used by mobile events.
##
## Animals face local +Z. Their bodies stay small enough to read at the event's
## 32px tile scale, while the named pivots give `AnimalMotion` a visual state
## without moving an event or inventing event timing.

static var _materials: Dictionary = {}


static func make_dog(kind: String = "loose") -> Node3D:
	var charging: bool = kind == "charging"
	var root: Node3D = Node3D.new()
	root.name = "Dog_%s" % kind
	root.set_meta("animal_kind", "charging_dog" if charging else "loose_dog")
	var coat: StandardMaterial3D = _material("dog_coat", Color("#6b543f"))
	var coat_dark: StandardMaterial3D = _material("dog_dark", Color("#3b2f26"))
	var muzzle: StandardMaterial3D = _material("dog_muzzle", Color("#b48662"))
	var eye: StandardMaterial3D = _material("dog_eye", Color("#221f28"))
	var mouth: StandardMaterial3D = _material("dog_mouth", Color("#c4503c"))

	var body: MeshInstance3D = _add_sphere(root, 0.20, Vector3(0.0, 0.32, 0.0), coat, "Body")
	body.scale = Vector3(1.22, 0.78 if not charging else 0.68, 1.60 if not charging else 1.92)
	var shoulder: MeshInstance3D = _add_sphere(root, 0.14, Vector3(0.0, 0.35, 0.25 if not charging else 0.34), coat, "Shoulder")
	shoulder.scale = Vector3(1.0, 0.9, 1.1)
	var head_y: float = 0.39 if not charging else 0.29
	var head_z: float = 0.37 if not charging else 0.52
	_add_sphere(root, 0.145, Vector3(0.0, head_y, head_z), coat, "Head")
	_add_box(root, Vector3(0.15, 0.10, 0.16), Vector3(0.0, head_y - 0.015, head_z + 0.115), muzzle, "Muzzle")
	_add_sphere(root, 0.022, Vector3(-0.07, head_y + 0.055, head_z + 0.105), eye, "LeftEye")
	_add_sphere(root, 0.022, Vector3(0.07, head_y + 0.055, head_z + 0.105), eye, "RightEye")
	_add_cone(root, 0.045, 0.0, 0.13, Vector3(-0.09, head_y + 0.12, head_z - 0.015), coat_dark, "LeftEar")
	_add_cone(root, 0.045, 0.0, 0.13, Vector3(0.09, head_y + 0.12, head_z - 0.015), coat_dark, "RightEar")
	if charging:
		_add_box(root, Vector3(0.13, 0.035, 0.07), Vector3(0.0, head_y - 0.07, head_z + 0.18), mouth, "OpenJaw")

	var leg_y: float = 0.29 if charging else 0.33
	var leg_z_front: float = 0.22 if not charging else 0.38
	var leg_z_back: float = -0.22 if not charging else -0.42
	_add_leg(root, "LeftFrontLegPivot", Vector3(-0.14, leg_y, leg_z_front), 0.28, coat_dark)
	_add_leg(root, "RightFrontLegPivot", Vector3(0.14, leg_y, leg_z_front), 0.28, coat_dark)
	_add_leg(root, "LeftBackLegPivot", Vector3(-0.14, leg_y, leg_z_back), 0.28, coat_dark)
	_add_leg(root, "RightBackLegPivot", Vector3(0.14, leg_y, leg_z_back), 0.28, coat_dark)

	if charging:
		_add_tail(root, coat_dark, Vector3(0.0, 0.34, -0.38), [Vector3(0.0, 0.34, -0.57), Vector3(0.0, 0.33, -0.73)], "Tail")
	else:
		_add_tail(root, coat_dark, Vector3(0.0, 0.38, -0.31), [Vector3(0.0, 0.49, -0.47), Vector3(0.0, 0.58, -0.56)], "Tail")
		# The loose dog keeps the old event's tell: a slack lead trailing on the ground.
		_add_cylinder_between(root, Vector3(0.0, 0.11, -0.42), Vector3(0.0, 0.07, -0.77), 0.012, coat_dark, "Lead")
	return root


static func make_cat() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Cat"
	root.set_meta("animal_kind", "cat")
	var coat: StandardMaterial3D = _material("cat_coat", Color("#58524d"))
	var dark: StandardMaterial3D = _material("cat_dark", Color("#3f3a36"))
	var eye: StandardMaterial3D = _material("cat_eye", Color("#d6a84e"))

	var body: MeshInstance3D = _add_sphere(root, 0.16, Vector3(0.0, 0.25, 0.0), coat, "Body")
	body.scale = Vector3(0.95, 0.70, 1.55)
	_add_sphere(root, 0.13, Vector3(0.0, 0.30, 0.29), coat, "Head")
	_add_sphere(root, 0.018, Vector3(-0.06, 0.34, 0.40), eye, "LeftEye")
	_add_sphere(root, 0.018, Vector3(0.06, 0.34, 0.40), eye, "RightEye")
	_add_cone(root, 0.04, 0.0, 0.12, Vector3(-0.08, 0.43, 0.27), dark, "LeftEar")
	_add_cone(root, 0.04, 0.0, 0.12, Vector3(0.08, 0.43, 0.27), dark, "RightEar")
	_add_leg(root, "LeftFrontLegPivot", Vector3(-0.105, 0.22, 0.22), 0.19, dark)
	_add_leg(root, "RightFrontLegPivot", Vector3(0.105, 0.22, 0.22), 0.19, dark)
	_add_leg(root, "LeftBackLegPivot", Vector3(-0.105, 0.22, -0.21), 0.19, dark)
	_add_leg(root, "RightBackLegPivot", Vector3(0.105, 0.22, -0.21), 0.19, dark)
	_add_tail(root, dark, Vector3(0.0, 0.28, -0.27), [Vector3(0.0, 0.38, -0.42), Vector3(0.0, 0.49, -0.51)], "Tail")
	return root


static func make_bird() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Bird"
	root.set_meta("animal_kind", "bird")
	var body_material: StandardMaterial3D = _material("bird_body", Color("#6b7a8c"))
	var wing_material: StandardMaterial3D = _material("bird_wing", Color("#8a97a8"))
	var dark: StandardMaterial3D = _material("bird_dark", Color("#5c697a"))
	var beak: StandardMaterial3D = _material("bird_beak", Color("#e8b64a"))
	var foot: StandardMaterial3D = _material("bird_foot", Color("#c4503c"))

	var body: MeshInstance3D = _add_sphere(root, 0.115, Vector3(0.0, 0.22, 0.0), body_material, "Body")
	body.scale = Vector3(0.9, 0.72, 1.22)
	_add_sphere(root, 0.085, Vector3(0.0, 0.27, 0.13), body_material, "Head")
	_add_box(root, Vector3(0.045, 0.035, 0.10), Vector3(0.0, 0.26, 0.22), beak, "Beak")
	_add_sphere(root, 0.012, Vector3(-0.035, 0.31, 0.19), dark, "LeftEye")
	_add_sphere(root, 0.012, Vector3(0.035, 0.31, 0.19), dark, "RightEye")
	var left_wing: Node3D = _add_wing(root, "LeftWingPivot", -1.0, wing_material)
	var right_wing: Node3D = _add_wing(root, "RightWingPivot", 1.0, wing_material)
	left_wing.set_meta("wing_side", -1.0)
	right_wing.set_meta("wing_side", 1.0)
	_add_box(root, Vector3(0.06, 0.04, 0.15), Vector3(-0.04, 0.09, -0.13), foot, "LeftFoot")
	_add_box(root, Vector3(0.06, 0.04, 0.15), Vector3(0.04, 0.09, -0.13), foot, "RightFoot")
	var tail: MeshInstance3D = _add_cone(root, 0.06, 0.0, 0.16, Vector3(0.0, 0.22, -0.15), dark, "Tail")
	tail.rotation.x = PI * 0.5
	return root


static func _material(key: String, color: Color, roughness: float = 0.84) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	_materials[key] = material
	return material


static func _add_box(parent: Node3D, size: Vector3, position: Vector3, material: StandardMaterial3D, name: String, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.rotation = rotation
	parent.add_child(instance)
	return instance


static func _add_sphere(parent: Node3D, radius: float, position: Vector3, material: StandardMaterial3D, name: String) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


static func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position: Vector3, material: StandardMaterial3D, name: String) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 8
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


static func _add_cone(parent: Node3D, bottom_radius: float, top_radius: float, height: float, position: Vector3, material: StandardMaterial3D, name: String) -> MeshInstance3D:
	return _add_cylinder(parent, top_radius, bottom_radius, height, position, material, name)


static func _add_leg(parent: Node3D, name: String, position: Vector3, length: float, material: StandardMaterial3D) -> void:
	var pivot: Node3D = Node3D.new()
	pivot.name = name
	pivot.position = position
	parent.add_child(pivot)
	var upper: float = length * 0.54
	var lower: float = length - upper
	_add_cylinder(pivot, 0.038, 0.045, upper, Vector3(0.0, -upper * 0.5, 0.0), material, "%sUpper" % name)
	var knee: Node3D = Node3D.new()
	knee.name = "%sKnee" % name
	knee.position = Vector3(0.0, -upper, 0.0)
	knee.rotation.x = -0.10 if name.contains("Front") else 0.08
	pivot.add_child(knee)
	_add_cylinder(knee, 0.034, 0.030, lower, Vector3(0.0, -lower * 0.5, 0.0), material, "%sLower" % name)
	_add_box(knee, Vector3(0.075, 0.035, 0.10), Vector3(0.0, -lower - 0.01, 0.045), material, "%sPaw" % name)


static func _add_tail(parent: Node3D, material: StandardMaterial3D, start: Vector3, points: Array[Vector3], name: String) -> void:
	var previous: Vector3 = start
	var index: int = 0
	for point: Vector3 in points:
		_add_cylinder_between(parent, previous, point, 0.035 - index * 0.006, material, "%sSegment%d" % [name, index])
		previous = point
		index += 1


static func _add_wing(parent: Node3D, name: String, side: float, material: StandardMaterial3D) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.name = name
	pivot.position = Vector3(side * 0.095, 0.27, 0.0)
	parent.add_child(pivot)
	_add_box(pivot, Vector3(0.16, 0.025, 0.22), Vector3(side * 0.07, 0.0, -0.015), material, "%sMesh" % name, Vector3(0.0, side * 0.20, side * 0.20))
	return pivot


static func _add_cylinder_between(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: StandardMaterial3D, name: String) -> MeshInstance3D:
	var direction: Vector3 = end - start
	var instance: MeshInstance3D = _add_cylinder(parent, radius, radius * 0.82, direction.length(), (start + end) * 0.5, material, name)
	instance.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return instance
