extends RefCounted
## Procedural dream forest. The playable path stays open between the bed and gate.


func build(g: Node3D) -> void:
	_build(g)


func _build(g) -> void:
	_make_materials(g)
	g.box(g, Vector3(0, -0.18, 0), Vector3(50, 0.35, 50), "moss", true)
	# Patches of velvety growth break up the broad ground plane.
	for i in range(46):
		var a: float = float(i) * 2.39996
		var r: float = 2.8 + float((i * 17) % 29) * 0.33
		var p := Vector3(cos(a) * r, 0.009, sin(a) * r)
		var patch: MeshInstance3D = g.sphere(g, p, 1.0 + float(i % 4) * 0.25, "moss_light" if i % 3 == 0 else "moss_dark", Vector3(1.35, 0.015, 0.75))
		patch.rotation.y = a
	# Pale stepping stones guide the eye through the clearing.
	for i in range(12):
		var z: float = 3.0 - float(i) * 1.06
		var x: float = 0.42 * sin(float(i) * 0.85)
		var stone: MeshInstance3D = g.sphere(g, Vector3(x, 0.026, z), 0.42, "stone", Vector3(1.25, 0.09, 0.78))
		stone.rotation.y = float(i) * 0.47
	# The trees make a ring, with an open view down the central path.
	for i in range(25):
		var a: float = TAU * float(i) / 25.0
		var r: float = 10.6 + float((i * 7) % 5) * 0.49
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if p.z < -8.0 and absf(p.x) < 3.0:
			continue
		_tree(g, p, i)
	# Distant trunks close the horizon and make the clearing feel enclosed by forest.
	for i in range(22):
		var angle: float = TAU * float(i) / 22.0 + 0.09
		var radius: float = 17.0 + float(i % 4) * 0.7
		_tree(g, Vector3(cos(angle) * radius, 0, sin(angle) * radius), i + 28)
	for i in range(57):
		var a: float = float(i) * 2.39996
		var r: float = 4.3 + float((i * 11) % 51) * 0.18
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if (p - Vector3(0, 0, 4)).length() < 2.4 or (absf(p.x) < 1.7 and p.z > -10.5 and p.z < 3.0):
			continue
		_fern(g, p, 0.72 + float(i % 4) * 0.11)
	for i in range(105):
		var a: float = float(i) * 2.39996
		var r: float = 2.8 + float((i * 19) % 63) * 0.17
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if absf(p.x) < 1.2 and p.z > -10.4 and p.z < 2.9:
			continue
		_flower(g, p, i)
	_bed(g)
	_note(g)
	_phone(g)
	_pavilion(g)
	_music_box(g)
	_mirror(g)
	_door(g)
	# A pair of improbable lanterns float above the route.
	for i in range(7):
		var x: float = -2.7 + float(i) * 0.9
		var z: float = 0.8 - float(i) * 1.28
		g.sphere(g, Vector3(x, 3.35 + float(i % 3) * 0.3, z), 0.19, "glow", Vector3(1, 1.18, 1))
		g.cylinder(g, Vector3(x, 3.58 + float(i % 3) * 0.3, z), 0.022, 0.16, "brass")


func _make_materials(g) -> void:
	var colors: Dictionary = {
		"moss": Color("6b927b"), "moss_light": Color("91b59a"), "moss_dark": Color("527a68"),
		"leaf": Color("76a88c"), "leaf_light": Color("aad0ac"), "bark": Color("736252"),
		"mint": Color("a4d2bd"), "mint_dark": Color("639f8f"), "lilac": Color("bca9c8"),
		"flower": Color("f2bfca"), "flower_cream": Color("f6e4bd"), "stone": Color("bdc9bd"),
		"glow": Color("fff3cf"), "blanket": Color("e5c8ce"), "tea": Color("f8eed7")
	}
	for id in colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[id]
		mat.roughness = 0.82
		g.materials[id] = mat
	# A small tiled noise map gives the clearing fine grass variation without
	# placing thousands of individual blades or carrying an external image.
	var grass_noise := FastNoiseLite.new()
	grass_noise.seed = 1482
	grass_noise.frequency = 0.065
	grass_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	grass_noise.fractal_octaves = 3
	var grass_palette := Gradient.new()
	grass_palette.set_color(0, Color("547663"))
	grass_palette.add_point(0.35, Color("6b927b"))
	grass_palette.add_point(0.68, Color("87aa8d"))
	grass_palette.set_color(1, Color("a3bd9b"))
	var grass_texture := NoiseTexture2D.new()
	grass_texture.width = 256
	grass_texture.height = 256
	grass_texture.noise = grass_noise
	grass_texture.color_ramp = grass_palette
	g.materials["moss"].albedo_color = Color.WHITE
	g.materials["moss"].albedo_texture = grass_texture
	g.materials["moss"].uv1_scale = Vector3(5, 5, 1)
	g.materials["glow"].emission_enabled = true
	g.materials["glow"].emission = Color("ffe6ab")
	g.materials["glow"].emission_energy_multiplier = 0.8


func _tree(g, p: Vector3, index: int) -> void:
	var h: float = 5.2 + float(index % 5) * 0.42
	var trunk_radius: float = 0.29 + float(index % 3) * 0.04
	g.cylinder(g, p + Vector3(0, h * 0.5, 0), trunk_radius, h, "bark")
	var trunk_body := StaticBody3D.new()
	var trunk_collision := CollisionShape3D.new()
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = trunk_radius
	trunk_shape.height = h
	trunk_collision.shape = trunk_shape
	trunk_body.add_child(trunk_collision)
	g.add_child(trunk_body)
	trunk_body.position = p + Vector3(0, h * 0.5, 0)
	g.sphere(g, p + Vector3(0, h * 0.65, 0), 0.36, "moss_dark", Vector3(1.2, 0.8, 1.1))
	for j in range(4):
		var a: float = TAU * float(j) / 4.0 + float(index) * 0.7
		var top := p + Vector3(cos(a) * 0.64, h + 0.3 + float(j % 2) * 0.24, sin(a) * 0.64)
		g.sphere(g, top, 1.0, "leaf_light" if (index + j) % 3 == 0 else "leaf", Vector3(1.2, 0.85, 1.13))
		g.sphere(g, top + Vector3(0, -0.48, 0), 0.62, "moss_dark", Vector3(1.0, 0.25, 1.0))
	for j in range(3):
		var a: float = TAU * float(j) / 3.0 + float(index)
		g.sphere(g, p + Vector3(cos(a) * 0.38, 0.13, sin(a) * 0.38), 0.31, "moss_light", Vector3(1.2, 0.5, 1))


func _fern(g, p: Vector3, size: float) -> void:
	for j in range(5):
		var a: float = float(j) * TAU / 5.0
		var dir := Vector3(cos(a), 0, sin(a))
		var leaf: MeshInstance3D = g.sphere(g, p + dir * size * 0.31 + Vector3(0, size * 0.29, 0), size * 0.36, "leaf_light" if j % 2 else "leaf", Vector3(0.28, 0.45, 1.35))
		leaf.rotation.y = -a + PI * 0.5


func _flower(g, p: Vector3, index: int) -> void:
	var h: float = 0.22 + float(index % 4) * 0.04
	g.cylinder(g, p + Vector3(0, h * 0.5, 0), 0.018, h, "mint_dark")
	for j in range(5):
		var a: float = TAU * float(j) / 5.0
		g.sphere(g, p + Vector3(cos(a) * 0.085, h, sin(a) * 0.085), 0.068, "flower" if index % 3 else "lilac", Vector3(1, 0.46, 1))
	g.sphere(g, p + Vector3(0, h + 0.012, 0), 0.045, "flower_cream")


func _bed(g) -> void:
	g.bed = Node3D.new()
	g.add_child(g.bed)
	g.bed.position = Vector3(0, 0, 4)
	var b: Node3D = g.bed
	# Thin iron frame and curled headboard keep the bed light in the landscape.
	for x in [-1.16, 1.16]:
		for z in [-1.43, 1.43]:
			g.cylinder(b, Vector3(x, 0.76, z), 0.055, 1.52, "mint_dark")
			g.sphere(b, Vector3(x, 1.58, z), 0.09, "brass")
		for z in [-1.37, 1.37]:
			g.box(b, Vector3(x, 0.68, z), Vector3(0.05, 0.12, 0.12), "mint_dark")
	for z in [-1.43, 1.43]:
		g.box(b, Vector3(0, 0.58, z), Vector3(2.34, 0.075, 0.055), "mint_dark")
		g.box(b, Vector3(0, 1.36 if z > 0 else 0.92, z), Vector3(2.31, 0.06, 0.05), "mint")
		for x in [-0.83, -0.42, 0.0, 0.42, 0.83]:
			g.cylinder(b, Vector3(x, 1.02 if z > 0 else 0.78, z), 0.025, 0.54 if z > 0 else 0.25, "mint")
	g.box(b, Vector3(0, 0.55, 0), Vector3(2.22, 0.17, 2.68), "mint_dark", true)
	g.box(b, Vector3(0, 0.69, 0), Vector3(2.1, 0.15, 2.58), "cream")
	g.box(b, Vector3(0, 0.78, -0.35), Vector3(2.06, 0.08, 1.83), "blanket")
	g.box(b, Vector3(0, 0.83, -1.22), Vector3(2.05, 0.075, 0.16), "lilac")
	for x in [-0.53, 0.53]:
		g.sphere(b, Vector3(x, 0.82, 0.96), 0.31, "tea", Vector3(1.4, 0.36, 0.77))
	for row in range(4):
		for col in range(5):
			var x: float = -0.78 + float(col) * 0.39
			var z: float = -1.06 + float(row) * 0.42
			g.sphere(b, Vector3(x, 0.838, z), 0.055, "flower" if (row + col) % 2 else "flower_cream", Vector3(1, 0.12, 0.6))
			g.sphere(b, Vector3(x + 0.065, 0.84, z + 0.04), 0.04, "leaf", Vector3(0.8, 0.08, 1.2))
	for z in [-1.2, 0, 1.2]:
		g.sphere(b, Vector3(-1.11, 0.69, z), 0.06, "brass")


func _note(g) -> void:
	g.cylinder(g, Vector3(1.72, 0.52, 3.45), 0.28, 1.03, "mint_dark")
	g.cylinder(g, Vector3(1.72, 1.06, 3.45), 0.43, 0.065, "mint")
	g.box(g, Vector3(1.72, 1.105, 3.45), Vector3(0.51, 0.018, 0.37), "paper")
	for i in range(3):
		g.box(g, Vector3(1.69, 1.118, 3.36 + float(i) * 0.075), Vector3(0.34, 0.005, 0.009), "wood")
	g.cylinder(g, Vector3(2.02, 1.16, 3.55), 0.06, 0.11, "brass")
	g.targets["note"] = Vector3(1.72, 0, 3.45)
	g.interaction_centers["note"] = Vector3(1.72, 1.11, 3.45)
	g.interaction_sizes["note"] = Vector3(0.61, 0.18, 0.47)


func _phone(g) -> void:
	g.cylinder(g, Vector3(-3.05, 0.48, -3.25), 0.33, 0.94, "mint_dark")
	g.cylinder(g, Vector3(-3.05, 0.97, -3.25), 0.54, 0.075, "mint")
	g.box(g, Vector3(-3.05, 1.08, -3.25), Vector3(0.49, 0.16, 0.35), "black")
	g.cylinder(g, Vector3(-3.05, 1.18, -3.17), 0.14, 0.025, "brass")
	for x in [-3.29, -2.81]:
		g.sphere(g, Vector3(x, 1.32, -3.31), 0.095, "black")
	g.box(g, Vector3(-3.05, 1.35, -3.31), Vector3(0.57, 0.075, 0.13), "black")
	g.targets["phone"] = Vector3(-3.05, 0, -2.85)
	g.interaction_centers["phone"] = Vector3(-3.05, 1.18, -3.25)
	g.interaction_sizes["phone"] = Vector3(0.75, 0.55, 0.6)


func _pavilion(g) -> void:
	var p := Vector3(-7.0, 0, -6.2)
	g.cylinder(g, p + Vector3(0, 0.13, 0), 2.65, 0.25, "stone")
	g.cylinder(g, p + Vector3(0, 0.27, 0), 2.42, 0.07, "mint")
	for i in range(10):
		var a: float = TAU * float(i) / 10.0
		var rim := p + Vector3(cos(a) * 2.14, 0, sin(a) * 2.14)
		g.cylinder(g, rim + Vector3(0, 1.73, 0), 0.047, 3.1, "cream")
		g.sphere(g, rim + Vector3(0, 3.24, 0), 0.13, "brass")
		g.sphere(g, rim + Vector3(0, 2.98, 0), 0.33, "flower" if i % 2 else "mint", Vector3(1.3, 0.55, 0.7))
	var roof: MeshInstance3D = g.cylinder(g, p + Vector3(0, 3.38, 0), 2.25, 0.36, "tea")
	(roof.mesh as CylinderMesh).top_radius = 0.32
	g.sphere(g, p + Vector3(0, 3.65, 0), 0.22, "brass")
	for i in range(5):
		var a: float = TAU * float(i) / 5.0
		_teacup(g, p + Vector3(cos(a) * 1.33, 0.33, sin(a) * 1.33), a, i)


func _teacup(g, p: Vector3, angle: float, index: int) -> void:
	var cup := Node3D.new()
	g.add_child(cup)
	cup.position = p
	cup.rotation.y = angle
	g.cylinder(cup, Vector3(0, 0.08, 0), 0.55, 0.15, "brass")
	g.cylinder(cup, Vector3(0, 0.19, 0), 0.43, 0.13, "mint_dark")
	var bowl: MeshInstance3D = g.cylinder(cup, Vector3(0, 0.53, 0), 0.53, 0.58, "flower" if index % 2 else "mint")
	(bowl.mesh as CylinderMesh).bottom_radius = 0.37
	g.cylinder(cup, Vector3(0, 0.83, 0), 0.54, 0.045, "cream")
	g.cylinder(cup, Vector3(0, 0.85, 0), 0.43, 0.025, "tea")
	# A real torus makes the oversized handle read clearly from a distance.
	var handle := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.18
	torus.outer_radius = 0.27
	handle.mesh = torus
	handle.material_override = g.materials["cream"]
	cup.add_child(handle)
	handle.position = Vector3(0.61, 0.57, 0)
	handle.rotation.z = PI * 0.5
	for j in range(3):
		g.sphere(cup, Vector3(-0.2 + float(j) * 0.2, 0.54, -0.47), 0.045, "flower_cream")


func _music_box(g) -> void:
	g.cylinder(g, Vector3(-4.8, 0.45, -5.1), 0.31, 0.9, "mint_dark")
	g.cylinder(g, Vector3(-4.8, 0.93, -5.1), 0.5, 0.08, "mint")
	g.box(g, Vector3(-4.8, 1.08, -5.1), Vector3(0.72, 0.27, 0.5), "wood")
	g.box(g, Vector3(-4.8, 1.23, -5.1), Vector3(0.73, 0.045, 0.52), "brass")
	for x in [-5.04, -4.8, -4.56]:
		g.sphere(g, Vector3(x, 1.27, -5.0), 0.07, "flower")
	g.targets["music"] = Vector3(-4.8, 0, -4.5)
	g.interaction_centers["music"] = Vector3(-4.8, 1.15, -5.1)
	g.interaction_sizes["music"] = Vector3(0.86, 0.43, 0.63)
	g.key_mesh = Node3D.new()
	g.add_child(g.key_mesh)
	g.key_mesh.position = Vector3(-4.8, 1.39, -5.09)
	g.cylinder(g.key_mesh, Vector3.ZERO, 0.075, 0.022, "brass")
	g.box(g.key_mesh, Vector3(0.12, 0, 0), Vector3(0.22, 0.035, 0.045), "brass")
	g.box(g.key_mesh, Vector3(0.2, 0, 0.05), Vector3(0.045, 0.035, 0.12), "brass")


func _mirror(g) -> void:
	var p := Vector3(3.55, 0, -4.1)
	g.box(g, p + Vector3(0, 0.09, 0), Vector3(1.86, 0.17, 0.8), "stone")
	g.box(g, p + Vector3(0, 1.4, -0.13), Vector3(1.61, 2.72, 0.21), "bark")
	g.box(g, p + Vector3(0, 1.4, 0.005), Vector3(1.34, 2.44, 0.03), "glass")
	for x in [-0.7, 0.7]:
		g.cylinder(g, p + Vector3(x, 1.4, 0.07), 0.055, 2.79, "moss_dark")
		for j in range(5):
			g.sphere(g, p + Vector3(x + (0.05 if x < 0 else -0.05), 0.4 + float(j) * 0.43, 0.12), 0.14, "leaf_light", Vector3(0.8, 0.48, 0.4))
	for i in range(9):
		var x: float = -0.69 + float(i) * 0.17
		g.sphere(g, p + Vector3(x, 2.77 + 0.18 * sin(float(i) * PI / 8.0), 0.06), 0.15, "moss_light", Vector3(1, 0.6, 0.5))
	g.targets["mirror"] = p + Vector3(0, 0, 0.63)
	g.interaction_centers["mirror"] = p + Vector3(0, 1.4, 0.04)
	g.interaction_sizes["mirror"] = Vector3(1.45, 2.55, 0.18)
	g.shadow_guest = Node3D.new()
	g.add_child(g.shadow_guest)
	g.shadow_guest.position = p + Vector3(0, 0.47, 0.07)
	g.sphere(g.shadow_guest, Vector3(0, 0.57, 0), 0.28, "shadow", Vector3(0.8, 1.55, 0.09))
	g.sphere(g.shadow_guest, Vector3(0, 1.1, 0), 0.21, "shadow", Vector3(1, 1, 0.11))
	for x in [-0.12, 0.12]:
		g.sphere(g.shadow_guest, Vector3(x, 1.44, 0), 0.075, "shadow", Vector3(0.7, 3.1, 0.12))


func _door(g) -> void:
	var p := Vector3(1, 0, -10)
	for x in [-0.87, 0.87]:
		g.box(g, p + Vector3(x, 1.49, 0), Vector3(0.13, 2.98, 0.22), "mint_dark")
	g.box(g, p + Vector3(0, 3.02, 0), Vector3(1.88, 0.13, 0.23), "mint_dark")
	g.box(g, p + Vector3(0, 1.43, 0), Vector3(1.6, 2.78, 0.11), "mint")
	g.box(g, p + Vector3(0, 2.38, 0.07), Vector3(1.34, 0.66, 0.035), "glass")
	for x in [-0.42, 0, 0.42]:
		g.box(g, p + Vector3(x, 2.38, 0.1), Vector3(0.035, 0.66, 0.035), "cream")
	for y in [0.58, 1.33, 2.03]:
		g.box(g, p + Vector3(0, y, 0.075), Vector3(1.33, 0.045, 0.03), "cream")
	g.sphere(g, p + Vector3(0.53, 1.18, 0.15), 0.075, "brass")
	for x in [-1.15, 1.15]:
		g.cylinder(g, p + Vector3(x, 0.5, 0), 0.27, 0.82, "stone")
		g.sphere(g, p + Vector3(x, 0.95, 0), 0.36, "flower", Vector3(1.1, 0.7, 1.1))
	g.targets["door"] = p + Vector3(0, 0, 0.7)
	g.interaction_centers["door"] = p + Vector3(0, 1.43, 0.06)
	g.interaction_sizes["door"] = Vector3(1.65, 2.8, 0.18)
