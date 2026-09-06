class_name ActorModels extends RefCounted
## Builds the small, articulated 3D silhouettes used by the orthographic city.
##
## One world unit is one 32px tile. Models face local +Z, which keeps a heading
## meaningful for both pedestrians and traffic without asking callers to special-case
## the camera's view.

const PERSON_HEIGHT: float = 1.35
const PRAM_LENGTH: float = 0.90

static func make_person(kind: String = "mother") -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Person_%s" % kind
	root.set_meta("actor_kind", kind)
	var palette: Dictionary = _person_palette(kind)

	var coat: StandardMaterial3D = _material(palette["coat"])
	var coat_dark: StandardMaterial3D = _material(palette["coat_dark"])
	var skin: StandardMaterial3D = _material(palette["skin"])
	var hair: StandardMaterial3D = _material(palette["hair"])
	var shoe: StandardMaterial3D = _material(palette["shoe"])
	var accent: StandardMaterial3D = _material(palette["accent"])

	# The body is a warm, tapered coat rather than a featureless capsule.
	_add_cylinder(root, 0.19, 0.23, 0.54, 12, Vector3(0.0, 0.70, 0.0), coat, "Torso")
	_add_cylinder(root, 0.23, 0.18, 0.16, 12, Vector3(0.0, 0.42, 0.0), coat_dark, "CoatHem")
	_add_box(root, Vector3(0.16, 0.05, 0.10), Vector3(0.0, 0.98, 0.17), accent, "Collar")

	_add_limb(root, "LeftLegPivot", Vector3(-0.085, 0.43, 0.0), 0.40, 0.055, shoe, Vector3(-0.085, 0.20, 0.055))
	_add_limb(root, "RightLegPivot", Vector3(0.085, 0.43, 0.0), 0.40, 0.055, shoe, Vector3(0.085, 0.20, 0.055))

	var left_arm: Node3D = _add_limb(root, "LeftArmPivot", Vector3(-0.205, 0.91, 0.0), 0.39, 0.045, coat, Vector3.ZERO)
	var right_arm: Node3D = _add_limb(root, "RightArmPivot", Vector3(0.205, 0.91, 0.0), 0.39, 0.045, coat, Vector3.ZERO)
	_add_sphere(left_arm, 0.058, Vector3(0.0, -0.225, 0.0 if kind != "mother" else 0.15), skin, "LeftHand")
	_add_sphere(right_arm, 0.058, Vector3(0.0, -0.225, 0.0 if kind != "mother" else 0.15), skin, "RightHand")

	# A head, hair mass and face plane give a readable profile at city scale.
	_add_sphere(root, 0.155, Vector3(0.0, 1.135, 0.015), skin, "Head")
	var hair_mesh: MeshInstance3D = _add_sphere(root, 0.165, Vector3(0.0, 1.18, -0.035), hair, "Hair")
	hair_mesh.scale = Vector3(1.0, 0.84, 0.86)
	_add_box(root, Vector3(0.105, 0.055, 0.018), Vector3(0.0, 1.12, 0.158), skin, "Face")

	match kind:
		"police":
			_add_cylinder(root, 0.17, 0.19, 0.07, 12, Vector3(0.0, 1.32, 0.0), accent, "PoliceCap")
			_add_box(root, Vector3(0.17, 0.025, 0.045), Vector3(0.0, 1.28, 0.15), accent, "CapBrim")
		"worker":
			_add_box(root, Vector3(0.30, 0.045, 0.18), Vector3(0.0, 0.82, 0.185), accent, "WorkVest")
			_add_box(root, Vector3(0.025, 0.04, 0.19), Vector3(0.0, 0.82, 0.19), coat_dark, "VestSeam")
		"civilian":
			_add_box(root, Vector3(0.08, 0.11, 0.025), Vector3(0.0, 0.69, 0.22), accent, "Scarf")
		"mother":
			# The hands are forward so a parented handle can meet them without
			# changing this pure person model's geometry.
			_add_box(root, Vector3(0.10, 0.13, 0.025), Vector3(0.0, 0.80, 0.22), accent, "CoatButton")

	return root


static func make_pram() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Pram"
	root.set_meta("actor_kind", "pram")
	var navy: StandardMaterial3D = _material(Color("#253b58"))
	var navy_dark: StandardMaterial3D = _material(Color("#17273d"))
	var cloth: StandardMaterial3D = _material(Color("#d0b08c"))
	var metal: StandardMaterial3D = _material(Color("#9a8062"), 0.62, 0.15)
	var wheel: StandardMaterial3D = _material(Color("#2b2523"))

	_add_box(root, Vector3(0.56, 0.13, 0.62), Vector3(0.0, 0.43, 0.08), navy, "BasketBody")
	_add_box(root, Vector3(0.62, 0.06, 0.68), Vector3(0.0, 0.34, 0.08), navy_dark, "BasketBase")
	_add_box(root, Vector3(0.50, 0.34, 0.055), Vector3(0.0, 0.59, 0.385), cloth, "FrontApron")
	var canopy: MeshInstance3D = _add_sphere(root, 0.34, Vector3(0.0, 0.74, 0.02), navy, "Canopy")
	canopy.scale = Vector3(0.95, 0.56, 0.78)
	_add_box(root, Vector3(0.48, 0.03, 0.03), Vector3(0.0, 0.73, 0.34), navy_dark, "CanopyRim")

	# The handle is two warm metal rails behind the basket, leaving a clear
	# place for the mother's forward hands in a composed rig.
	_add_cylinder_between(root, Vector3(-0.18, 0.54, -0.26), Vector3(-0.18, 0.78, -0.43), 0.018, metal, "HandleLeft")
	_add_cylinder_between(root, Vector3(0.18, 0.54, -0.26), Vector3(0.18, 0.78, -0.43), 0.018, metal, "HandleRight")
	_add_cylinder_between(root, Vector3(-0.18, 0.78, -0.43), Vector3(0.18, 0.78, -0.43), 0.025, metal, "HandleGrip")

	_add_pram_wheel(root, "WheelRearLeft", Vector3(-0.24, 0.18, -0.27), wheel)
	_add_pram_wheel(root, "WheelRearRight", Vector3(0.24, 0.18, -0.27), wheel)
	_add_pram_wheel(root, "WheelFrontLeft", Vector3(-0.24, 0.18, 0.35), wheel)
	_add_pram_wheel(root, "WheelFrontRight", Vector3(0.24, 0.18, 0.35), wheel)
	return root


static func make_mother_rig() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "MotherRig"
	var person: Node3D = make_person("mother")
	person.name = "Mother"
	root.add_child(person)
	var pram: Node3D = make_pram()
	pram.position = Vector3(0.0, 0.0, 0.58)
	root.add_child(pram)
	return root


static func make_vehicle(kind: String = "car") -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Vehicle_%s" % kind
	root.set_meta("actor_kind", kind)
	var palette: Dictionary = _vehicle_palette(kind)
	var body: StandardMaterial3D = _material(palette["body"])
	var body_dark: StandardMaterial3D = _material(palette["body_dark"])
	var window: StandardMaterial3D = _material(palette["window"])
	var trim: StandardMaterial3D = _material(palette["trim"], 0.48, 0.25)
	var tire: StandardMaterial3D = _material(Color("#242224"))
	var lamp: StandardMaterial3D = _material(Color("#f3d991"), 0.28, 0.0)
	var tail: StandardMaterial3D = _material(Color("#a63c34"), 0.4, 0.0)

	var length: float = 1.42
	var width: float = 0.76
	var body_height: float = 0.34
	var cabin_height: float = 0.42
	match kind:
		"van":
			length = 1.58
			width = 0.80
			body_height = 0.36
			cabin_height = 0.52
		"truck":
			length = 1.78
			width = 0.82
			body_height = 0.30
			cabin_height = 0.47
		"armored":
			length = 1.52
			width = 0.84
			body_height = 0.40
			cabin_height = 0.46

	_add_box(root, Vector3(width, 0.16, length), Vector3(0.0, 0.27, 0.0), body_dark, "Chassis")
	_add_box(root, Vector3(width * 0.94, body_height, length * 0.91), Vector3(0.0, 0.48, 0.0), body, "LowerBody")
	_add_box(root, Vector3(width * 0.88, cabin_height, length * 0.48), Vector3(0.0, 0.81, -0.12), body, "Cabin")
	_add_box(root, Vector3(width * 0.91, 0.06, 0.20), Vector3(0.0, 0.67, length * 0.34), body, "Hood")
	_add_box(root, Vector3(width * 0.98, 0.06, 0.08), Vector3(0.0, 0.33, length * 0.49), trim, "FrontBumper")
	_add_box(root, Vector3(width * 0.98, 0.06, 0.08), Vector3(0.0, 0.33, -length * 0.49), trim, "RearBumper")

	# Separate window pieces and a belt line make the shell read as a vehicle
	# from the orthographic angle instead of a coloured block.
	_add_box(root, Vector3(width * 0.67, cabin_height * 0.55, 0.025), Vector3(0.0, 0.84, 0.125), window, "Windshield")
	_add_box(root, Vector3(width * 0.66, cabin_height * 0.55, 0.025), Vector3(0.0, 0.84, -0.36), window, "RearWindow")
	_add_box(root, Vector3(0.025, cabin_height * 0.52, 0.28), Vector3(width * 0.445, 0.84, -0.12), window, "SideWindowRight")
	_add_box(root, Vector3(0.025, cabin_height * 0.52, 0.28), Vector3(-width * 0.445, 0.84, -0.12), window, "SideWindowLeft")
	_add_box(root, Vector3(width * 0.98, 0.035, length * 0.84), Vector3(0.0, 0.68, 0.0), trim, "BeltLine")
	_add_box(root, Vector3(0.12, 0.05, 0.035), Vector3(-width * 0.30, 0.53, length * 0.47), lamp, "HeadlampLeft")
	_add_box(root, Vector3(0.12, 0.05, 0.035), Vector3(width * 0.30, 0.53, length * 0.47), lamp, "HeadlampRight")
	_add_box(root, Vector3(0.11, 0.05, 0.035), Vector3(-width * 0.30, 0.53, -length * 0.47), tail, "TailLampLeft")
	_add_box(root, Vector3(0.11, 0.05, 0.035), Vector3(width * 0.30, 0.53, -length * 0.47), tail, "TailLampRight")

	var wheel_z: Array[float] = [-length * 0.32, length * 0.32]
	for axle_z: float in wheel_z:
		_add_vehicle_wheel(root, "WheelFront" if axle_z > 0.0 else "WheelRear", axle_z, -1.0, width, tire)
		_add_vehicle_wheel(root, "WheelFront" if axle_z > 0.0 else "WheelRear", axle_z, 1.0, width, tire)

	match kind:
		"truck":
			_add_box(root, Vector3(width * 0.96, 0.50, length * 0.48), Vector3(0.0, 0.84, -length * 0.30), body_dark, "CargoBed")
			_add_box(root, Vector3(width * 0.98, 0.035, length * 0.44), Vector3(0.0, 1.11, -length * 0.30), trim, "CargoRoof")
		"armored":
			_add_box(root, Vector3(width * 0.92, 0.06, 0.58), Vector3(0.0, 1.10, -0.04), trim, "ArmorRoof")
			_add_box(root, Vector3(0.10, 0.16, 0.24), Vector3(0.0, 1.22, 0.04), trim, "RoofBeacon")
		"van":
			_add_box(root, Vector3(width * 0.84, 0.05, length * 0.34), Vector3(0.0, 1.10, -0.27), body_dark, "VanRoofRidge")

	return root


static func _person_palette(kind: String) -> Dictionary:
	match kind:
		"civilian":
			return {"coat": Color("#4d7d78"), "coat_dark": Color("#315b59"), "skin": Color("#c98968"), "hair": Color("#3a2929"), "shoe": Color("#352b35"), "accent": Color("#d6a95f")}
		"worker":
			return {"coat": Color("#b56b3e"), "coat_dark": Color("#74432e"), "skin": Color("#a96f56"), "hair": Color("#272329"), "shoe": Color("#302b2b"), "accent": Color("#e0bf55")}
		"police":
			return {"coat": Color("#304c6e"), "coat_dark": Color("#1d304b"), "skin": Color("#bd8067"), "hair": Color("#25242a"), "shoe": Color("#1e252f"), "accent": Color("#d4b96d")}
		_:
			return {"coat": Color("#a95143"), "coat_dark": Color("#713530"), "skin": Color("#c98968"), "hair": Color("#39272b"), "shoe": Color("#302a30"), "accent": Color("#e3c17c")}


static func _vehicle_palette(kind: String) -> Dictionary:
	match kind:
		"van":
			return {"body": Color("#d3c5a1"), "body_dark": Color("#83745c"), "window": Color("#30495d"), "trim": Color("#5d574e")}
		"truck":
			return {"body": Color("#bd653d"), "body_dark": Color("#734232"), "window": Color("#263f51"), "trim": Color("#d09f62")}
		"armored":
			return {"body": Color("#59666a"), "body_dark": Color("#303d43"), "window": Color("#172a36"), "trim": Color("#7e8b83")}
		_:
			return {"body": Color("#b85f4c"), "body_dark": Color("#713d38"), "window": Color("#294557"), "trim": Color("#d1a76f")}


static func _material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
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


static func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, segments: int, position: Vector3, material: StandardMaterial3D, name: String) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


static func _add_sphere(parent: Node3D, radius: float, position: Vector3, material: StandardMaterial3D, name: String) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance


static func _add_limb(parent: Node3D, name: String, pivot_position: Vector3, length: float, radius: float, material: StandardMaterial3D, shoe_position: Vector3) -> Node3D:
	var pivot: Node3D = Node3D.new()
	pivot.name = name
	pivot.position = pivot_position
	parent.add_child(pivot)
	_add_cylinder(pivot, radius, radius * 1.08, length, 8, Vector3(0.0, -length * 0.5, 0.0), material, "%sMesh" % name)
	if shoe_position != Vector3.ZERO:
		_add_box(pivot, Vector3(0.105, 0.07, 0.18), Vector3(0.0, -length - 0.015, 0.055), material, "%sShoe" % name)
	return pivot


static func _add_cylinder_between(parent: Node3D, start: Vector3, end: Vector3, radius: float, material: StandardMaterial3D, name: String) -> MeshInstance3D:
	var midpoint: Vector3 = (start + end) * 0.5
	var direction: Vector3 = end - start
	var instance: MeshInstance3D = _add_cylinder(parent, radius, radius, direction.length(), 8, midpoint, material, name)
	instance.quaternion = Quaternion(Vector3.UP, direction.normalized())
	return instance


static func _add_pram_wheel(parent: Node3D, name: String, position: Vector3, material: StandardMaterial3D) -> void:
	var pivot: Node3D = Node3D.new()
	pivot.name = name
	pivot.position = position
	pivot.rotation.z = PI * 0.5
	parent.add_child(pivot)
	_add_cylinder(pivot, 0.075, 0.075, 0.045, 12, Vector3.ZERO, material, "%sMesh" % name)


static func _add_vehicle_wheel(parent: Node3D, axle: String, z: float, side: float, width: float, material: StandardMaterial3D) -> void:
	var side_name: String = "Left" if side < 0.0 else "Right"
	var pivot: Node3D = Node3D.new()
	pivot.name = "%s%s" % [axle, side_name]
	pivot.position = Vector3(side * width * 0.53, 0.22, z)
	pivot.rotation.z = PI * 0.5
	parent.add_child(pivot)
	_add_cylinder(pivot, 0.125, 0.125, 0.065, 12, Vector3.ZERO, material, "%sMesh" % pivot.name)
	var arch: MeshInstance3D = _add_torus(pivot, 0.126, 0.145, material, "%sArch" % pivot.name)
	arch.rotation.z = PI * 0.5


static func _add_torus(parent: Node3D, inner_radius: float, outer_radius: float, material: StandardMaterial3D, name: String) -> MeshInstance3D:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 12
	mesh.ring_segments = 6
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = name
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance
