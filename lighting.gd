extends RefCounted
## Overcast skylight and a weak, warm sun; advanced effects use Forward+.
func configure(g, sun: DirectionalLight3D) -> void:
	var env: Environment = g.world_environment.environment
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("92a9b4")
	sky_material.sky_horizon_color = Color("d1d7c4")
	sky_material.ground_bottom_color = Color("5d7260")
	sky_material.ground_horizon_color = Color("c2cbbc")
	sky_material.sky_curve = 0.22
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.75
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.fog_density = 0.006
	env.fog_light_color = Color("bdcdc4")
	env.fog_light_energy = 0.4
	sun.name = "OvercastSun"
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_color = Color("fff0d5")
	sun.light_energy = 0.65
	sun.light_angular_distance = 2.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 45.0
	sun.shadow_bias = 0.025
	sun.shadow_normal_bias = 0.5
	sun.shadow_blur = 1.5
	g.lamp.light_size = 0.35
	g.lamp.light_energy = 0.38
	g.lamp.shadow_blur = 2.0
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		g.get_viewport().use_taa = true
		env.ssao_enabled = true
		env.ssao_radius = 1.05
		env.ssao_intensity = 1.0
		env.ssao_power = 1.4
		env.ssil_enabled = true
		env.ssil_radius = 3.0
		env.ssil_intensity = 0.5
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.007
		env.volumetric_fog_albedo = Color("bdccc1")
		env.volumetric_fog_length = 35.0
		env.volumetric_fog_detail_spread = 2.0
		env.glow_enabled = true
		env.glow_intensity = 0.18
		env.glow_hdr_threshold = 1.6
	_materials(g)
	_leaf_shadows(g)

func _materials(g) -> void:
	for id in ["moss", "moss_light", "moss_dark", "leaf", "leaf_light", "bark", "blanket", "coat", "rabbit"]:
		g.materials[id].roughness = 0.96
	g.materials["brass"].metallic = 0.75
	g.materials["brass"].roughness = 0.36
	for id in ["mint", "mint_dark", "tea", "lilac"]:
		g.materials[id].roughness = 0.43
	g.materials["glass"].metallic = 0.55
	g.materials["glass"].roughness = 0.22
	g.materials["glass"].emission_energy_multiplier = 0.08
	# Tiny surface irregularities keep cloth and bark from looking like plastic.
	var noise := FastNoiseLite.new()
	noise.seed = 381
	noise.frequency = 0.12
	var normal := NoiseTexture2D.new()
	normal.width = 128
	normal.height = 128
	normal.noise = noise
	normal.as_normal_map = true
	normal.bump_strength = 0.5
	for id in ["moss", "bark", "blanket"]:
		g.materials[id].normal_enabled = true
		g.materials[id].normal_texture = normal
		g.materials[id].normal_scale = 0.28 if id == "blanket" else 0.5

func _leaf_shadows(g) -> void:
	# Alpha-cutout leaf clusters form a real canopy silhouette in shadow maps.
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 6725
	for i in range(55):
		var center := Vector2(rng.randf_range(6, 122), rng.randf_range(6, 122))
		var angle := rng.randf_range(0, TAU)
		var length := rng.randf_range(5, 12)
		for y in range(maxi(0, int(center.y)-15), mini(128, int(center.y)+16)):
			for x in range(maxi(0, int(center.x)-15), mini(128, int(center.x)+16)):
				var offset := (Vector2(x, y) - center).rotated(-angle)
				if pow(offset.x / length, 2) + pow(offset.y / (length * 0.38), 2) < 1:
					image.set_pixel(x, y, Color("617d62"))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(image)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	for pos in [Vector3(-2.5, 5.5, 2.0), Vector3(0.5, 6.0, -1.0), Vector3(-5, 5.8, -5), Vector3(3.0, 5.6, -4.0)]:
		var canopy := MeshInstance3D.new()
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(4.5, 4.5)
		canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		canopy.set_meta("leaf_shadow_canopy", true)
		canopy.mesh = mesh
		canopy.material_override = mat
		g.add_child(canopy)
		canopy.position = pos
		canopy.rotation.y = rng.randf_range(0, TAU)
