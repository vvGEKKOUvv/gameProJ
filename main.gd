extends Node3D
## Original procedural short horror prototype. No third-party game assets.
const SPAWN_POS := Vector3(1.8, 0.03, 4.8)
var bed: Node3D
var wake_camera: Camera3D
var waking: bool = true
var wake_in_progress: bool = false
var wake_tween: Tween
var interaction_centers: Dictionary = {}
var interaction_sizes: Dictionary = {}
var stage: int = 0
var ended: bool = false
var dialog_open: bool = false
var current_target: String = ""
var player: CharacterBody3D
var rabbit: Node3D
var mouse_sensitivity: float = 0.0025
var camera_arm: SpringArm3D
var crosshair: Label
var camera: Camera3D
var lamp: OmniLight3D
var world_environment: WorldEnvironment
var shadow_guest: Node3D
var key_mesh: Node3D
var targets: Dictionary = {}
var objective_label: Label
var prompt_label: Label
var dialog_panel: PanelContainer
var dialog_title: Label
var dialog_text: Label
var ending_panel: PanelContainer
var chapter_label: Label
var ambience: AudioStreamPlayer
var tone: AudioStreamPlayer
var elapsed: float = 0.0
var audio_enabled: bool = true
var materials: Dictionary = {}
const OBJECTIVES: Array[String] = ["ベッドのそばの手紙を読む", "遊園地の電話を探す", "苔の鏡を調べる", "ティーカップのオルゴールを探す", "鍵を持って、森の扉へ"]
const NAMES: Dictionary = {"note": "置き手紙", "phone": "古い電話", "mirror": "姿見", "music": "オルゴール", "door": "森の扉", "window": "窓"}

func _ready() -> void:
	_setup_inputs()
	_build_materials()
	preload("res://forest.gd").new().build(self)
	_build_player()
	_build_lighting()
	_build_interaction_areas()
	_build_ui()
	_build_audio()
	_refresh_state()
	_intro()

func _intro() -> void:
	waking = true
	wake_in_progress = false
	rabbit.set_as_top_level(true)
	rabbit.position = Vector3(0, 0.94, 3.4)
	rabbit.rotation = Vector3(PI / 2, 0, 0)
	wake_camera.position = Vector3(3.2, 3.8, 7.8)
	wake_camera.look_at(Vector3(0, 0.9, 4))
	wake_camera.current = true
	show_dialog("まぶたの向こう", "目を開けると、森の中のベッドにいた。\n\nどこかで、遊園地の音楽が聞こえる。\nE / Enter で起き上がる。")

func _setup_inputs() -> void:
	var mappings: Dictionary = {"walk_left": [KEY_A, KEY_LEFT], "walk_right": [KEY_D, KEY_RIGHT], "walk_up": [KEY_W, KEY_UP], "walk_down": [KEY_S, KEY_DOWN], "interact": [KEY_E, KEY_ENTER, KEY_SPACE], "dismiss": [KEY_ESCAPE], "restart": [KEY_R], "mute": [KEY_M]}
	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in mappings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)

func _build_materials() -> void:
	var colors: Dictionary = {"wall": Color("56625b"), "trim": Color("313e37"), "floor": Color("856951"), "wood": Color("624633"), "darkwood": Color("362b28"), "cream": Color("e5d9ba"), "paper": Color("f2e4bd"), "sofa": Color("a76652"), "rug": Color("5b6961"), "rugline": Color("b6a984"), "brass": Color("b7995b"), "black": Color("252c2b"), "glass": Color("9bb7b0"), "rabbit": Color("e9ddc7"), "coat": Color("718782"), "pink": Color("c89085"), "shadow": Color("20292a")}
	for id in colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[id]
		mat.roughness = 0.9
		materials[id] = mat
	materials["brass"].metallic = 0.45
	materials["glass"].emission_enabled = true
	materials["glass"].emission = Color("547c79")
	materials["glass"].emission_energy_multiplier = 0.4

func box(parent: Node3D, pos: Vector3, size: Vector3, material_id: String, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = materials[material_id]
	parent.add_child(mesh)
	mesh.position = pos
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		collision.shape = box_shape
		body.add_child(collision)
		mesh.add_child(body)
	return mesh

func sphere(parent: Node3D, pos: Vector3, radius: float, material_id: String, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 12
	shape.rings = 6
	mesh.mesh = shape
	mesh.material_override = materials[material_id]
	parent.add_child(mesh)
	mesh.position = pos
	mesh.scale = scale_value
	return mesh

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, material_id: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 12
	mesh.mesh = shape
	mesh.material_override = materials[material_id]
	parent.add_child(mesh)
	mesh.position = pos
	return mesh

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Traveler"
	add_child(player)
	player.position = SPAWN_POS
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 1.1
	collision.shape = capsule
	collision.position.y = 0.56
	player.add_child(collision)
	rabbit = Node3D.new()
	player.add_child(rabbit)
	rabbit.rotation.y = PI
	sphere(rabbit, Vector3(0, 0.52, 0), 0.30, "coat", Vector3(1, 1.25, 0.85))
	sphere(rabbit, Vector3(0, 0.98, 0), 0.32, "rabbit", Vector3(1, 0.95, 0.90))
	for x in [-0.16, 0.16]:
		sphere(rabbit, Vector3(x, 1.43, 0), 0.105, "rabbit", Vector3(0.82, 3.0, 0.68))
		sphere(rabbit, Vector3(x, 1.43, 0.071), 0.07, "pink", Vector3(0.75, 3.2, 0.14))
		sphere(rabbit, Vector3(x * 0.70, 1.01, 0.267), 0.033, "black", Vector3(0.8, 1.2, 0.4))
		sphere(rabbit, Vector3(x * 1.25, 0.14, 0.09), 0.14, "rabbit", Vector3(0.8, 0.65, 1.25))
		sphere(rabbit, Vector3(x * 2, 0.55, 0), 0.13, "rabbit", Vector3(0.8, 1.6, 0.8))
	sphere(rabbit, Vector3(0, 0.93, 0.29), 0.045, "pink")
	sphere(rabbit, Vector3(0, 0.40, -0.26), 0.12, "rabbit")
	box(rabbit, Vector3(0, 0.70, 0.255), Vector3(0.43, 0.10, 0.04), "rugline")

func _build_lighting() -> void:
	world_environment = WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("c7d5c5")
	environment.fog_enabled = true
	environment.fog_light_color = Color("cfddd2")
	environment.fog_density = 0.009
	environment.fog_light_energy = 0.6
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c7c5ad")
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.tonemap_exposure = 0.72
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("fff2ce")
	sun.light_energy = 0.42
	sun.shadow_enabled = true
	lamp = OmniLight3D.new()
	add_child(lamp)
	lamp.position = Vector3(-4.0, 2.7, -4.0)
	lamp.light_color = Color("ffcc88")
	lamp.light_energy = 0.8
	lamp.omni_range = 7.0
	lamp.shadow_enabled = true
	preload("res://lighting.gd").new().configure(self, sun)
	camera_arm = SpringArm3D.new()
	player.add_child(camera_arm)
	camera_arm.position = Vector3(0.45, 1.9, 0)
	camera_arm.rotation.x = deg_to_rad(-8)
	camera_arm.spring_length = 2.05
	camera_arm.margin = 0.12
	camera_arm.collision_mask = 1
	var camera_shape := SphereShape3D.new()
	camera_shape.radius = 0.20
	camera_arm.shape = camera_shape
	camera_arm.add_excluded_object(player.get_rid())
	camera = Camera3D.new()
	camera_arm.add_child(camera)
	camera.position = Vector3.ZERO
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 68.0
	camera.near = 0.05
	camera.current = true
	wake_camera = Camera3D.new()
	add_child(wake_camera)
	wake_camera.fov = 65.0
	wake_camera.near = 0.05

func _build_interaction_areas() -> void:
	var positions: Dictionary = interaction_centers
	var sizes: Dictionary = interaction_sizes
	for id in positions:
		var area := Area3D.new()
		area.collision_layer = 2
		area.collision_mask = 0
		area.set_meta("interaction_id", id)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = sizes[id]
		collision.shape = shape
		area.add_child(collision)
		add_child(area)
		area.position = positions[id]

func _label(text_value: String, font_size: int, color_value: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color_value)
	return label

func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.set_corner_radius_all(3)
	return style

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Noto Sans CJK JP", "Yu Gothic", "Hiragino Sans", "sans-serif"])
	var theme := Theme.new()
	theme.default_font = font
	root.theme = theme
	var film := ColorRect.new()
	root.add_child(film)
	film.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	film.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform sampler2D screen_texture : hint_screen_texture, filter_nearest; void fragment(){ vec2 uv=SCREEN_UV; vec3 c=texture(screen_texture,uv).rgb; float vignette=1.0-0.36*pow(length((uv-0.5)*1.4),2.0); float grain=fract(sin(dot(floor(uv*vec2(1100.0,720.0)),vec2(12.9898,78.233))+floor(TIME*8.0))*43758.5453)-0.5; c=mix(c,vec3(dot(c,vec3(0.299,0.587,0.114))),0.08); COLOR=vec4(c*vignette+grain*0.008,1.0); }"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	film.material = shader_material
	var top_backdrop := ColorRect.new()
	root.add_child(top_backdrop)
	top_backdrop.color = Color(0.035, 0.07, 0.065, 0.78)
	top_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_backdrop.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_backdrop.offset_bottom = 133
	var bottom_backdrop := ColorRect.new()
	root.add_child(bottom_backdrop)
	bottom_backdrop.color = Color(0.035, 0.07, 0.065, 0.78)
	bottom_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_backdrop.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_backdrop.offset_top = -48
	var header := VBoxContainer.new()
	root.add_child(header)
	header.position = Vector2(36, 27)
	header.add_theme_constant_override("separation", 5)
	header.add_child(_label("THE GARDEN BETWEEN DREAMS", 12, Color("b7b6a0")))
	header.add_child(_label("まどろみの庭", 29, Color("efe4cc")))
	chapter_label = _label("01  /  雨宿り", 13, Color("a5b4ab"))
	header.add_child(chapter_label)
	var objective := VBoxContainer.new()
	root.add_child(objective)
	objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	objective.offset_left = -320
	objective.offset_right = -35
	objective.offset_top = 32
	objective.offset_bottom = 107
	objective.add_child(_label("旅のしおり  /  OBJECTIVE", 11, Color("a5b4ab")))
	objective_label = _label("", 16, Color("eee3cd"))
	objective.add_child(objective_label)
	var controls := _label("WASD：移動   マウス：見回す   E：調べる   Esc：マウス解除   M：音", 13, Color("a4b0a7"))
	controls.name = "ControlsLabel"
	root.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.offset_left = 36
	controls.offset_top = -36
	controls.offset_right = 940
	controls.offset_bottom = -14
	prompt_label = _label("", 18, Color("f1e7cd"))
	root.add_child(prompt_label)
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.offset_left = -250
	prompt_label.offset_right = 250
	prompt_label.offset_top = -81
	prompt_label.offset_bottom = -46
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_shadow_color", Color("172124"))
	prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	crosshair = _label("+", 22, Color("eee5cf"))
	root.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -12
	crosshair.offset_right = 12
	crosshair.offset_top = -16
	crosshair.offset_bottom = 16
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_panel = PanelContainer.new()
	root.add_child(dialog_panel)
	dialog_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_left = 160
	dialog_panel.offset_right = -160
	dialog_panel.offset_top = -260
	dialog_panel.offset_bottom = -58
	dialog_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.13, 0.13, 0.97), Color("758176")))
	var dialog_box := VBoxContainer.new()
	dialog_box.add_theme_constant_override("separation", 12)
	dialog_panel.add_child(dialog_box)
	dialog_title = _label("", 15, Color("c5b388"))
	dialog_box.add_child(dialog_title)
	dialog_text = _label("", 18, Color("eee5cf"))
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_box.add_child(dialog_text)
	var hint := _label("E / Enter：閉じる    Esc：閉じる", 12, Color("9aaa9f"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialog_box.add_child(hint)
	ending_panel = PanelContainer.new()
	root.add_child(ending_panel)
	ending_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.10, 0.10, 0.98), Color("253633")))
	var center := CenterContainer.new()
	ending_panel.add_child(center)
	var ending_box := VBoxContainer.new()
	ending_box.add_theme_constant_override("separation", 24)
	center.add_child(ending_box)
	for item in [["CHECK OUT", 14], ["まどろみの庭", 42], ["扉の向こうで、朝の匂いがした。\n\n目を覚ましたのだろうか。\nそれとも、夢の続きを歩いているのだろうか。", 20], ["END  /  朝の向こう", 15], ["R：もう一度遊ぶ", 16]]:
		var label := _label(item[0], item[1], Color("e0d8bb"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ending_box.add_child(label)
	ending_panel.hide()

func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	return stream

func _sample(data: PackedByteArray, sample: float) -> void:
	var value := int(sample * 32767.0)
	data.append(value & 255)
	data.append((value >> 8) & 255)

func _build_audio() -> void:
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	var data := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2796
	var dream_notes: Array[float] = [261.63, 329.63, 293.66]
	for i in range(22050 * 3):
		var t := float(i) / 22050.0
		var frequency: float = dream_notes[mini(int(t), 2)]
		var music := sin(t * TAU * frequency) * sin(PI * fmod(t, 1.0)) * 0.018
		_sample(data, rng.randf_range(-0.035, 0.035) + sin(t * TAU * 65.0) * 0.008 + music)
	var stream := _wav(data)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = 22050 * 3
	ambience.stream = stream
	ambience.volume_db = -12
	ambience.play()
	tone = AudioStreamPlayer.new()
	add_child(tone)
	tone.volume_db = -15

func _chime(frequency: float) -> void:
	if not audio_enabled:
		return
	var data := PackedByteArray()
	for i in range(11025):
		var t := float(i) / 22050.0
		_sample(data, (sin(TAU * frequency * t) + 0.3 * sin(TAU * frequency * 2.01 * t)) * exp(-t * 8.0) * 0.30)
	tone.stream = _wav(data)
	tone.play()

func _music_phrase() -> void:
	if not audio_enabled:
		return
	var data := PackedByteArray()
	var notes: Array[float] = [659.25, 783.99, 739.99, 587.33, 493.88, 659.25]
	for i in range(22050 * 2):
		var t := float(i) / 22050.0
		var note_index := mini(int(t / 0.33), notes.size() - 1)
		var local_time := fmod(t, 0.33)
		var frequency: float = notes[note_index]
		_sample(data, (sin(TAU * frequency * local_time) + 0.25 * sin(TAU * frequency * 3.0 * local_time)) * exp(-local_time * 13.0) * 0.26)
	tone.stream = _wav(data)
	tone.play()

func _apply_mouse_look(relative: Vector2) -> void:
	if dialog_open or ended or waking:
		return
	player.rotation.y -= relative.x * mouse_sensitivity
	camera_arm.rotation.x = clampf(camera_arm.rotation.x - relative.y * mouse_sensitivity, deg_to_rad(-55), deg_to_rad(25))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not dialog_open and not ended and not waking and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event.relative)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not dialog_open and not ended and not waking:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event.is_action_pressed("mute"):
		audio_enabled = not audio_enabled
		ambience.stream_paused = not audio_enabled
		if not audio_enabled:
			tone.stop()
	if ended:
		if event.is_action_pressed("restart"):
			restart_game()
		return
	if dialog_open:
		if event.is_action_pressed("interact") or event.is_action_pressed("dismiss"):
			close_dialog()
		return
	if waking:
		return
	if event.is_action_pressed("dismiss"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event.is_action_pressed("interact") and not current_target.is_empty():
		interact(current_target)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if stage >= 2 and not ended:
		lamp.light_energy = 0.25 + sin(elapsed * 11.0) * 0.08 + sin(elapsed * 27.0) * 0.04
	if ended or dialog_open or waking:
		player.velocity = Vector3.ZERO
		return
	var input_vector := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	var right := Vector3(camera.global_basis.x.x, 0, camera.global_basis.x.z).normalized()
	var back := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
	var direction := right * input_vector.x + back * input_vector.y
	player.velocity.x = direction.x * 2.5
	player.velocity.z = direction.z * 2.5
	player.velocity.y -= 15.0 * delta
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -13.0, 13.0)
	player.position.z = clampf(player.position.z, -13.0, 13.0)
	if direction.length_squared() > 0.01:
		rabbit.position.y = absf(sin(elapsed * 10.0)) * 0.035
	else:
		rabbit.position.y = 0.0
	_update_target()

func _update_target() -> void:
	current_target = ""
	var start := camera.global_position
	var finish := start - camera.global_basis.z * 4.5
	var query := PhysicsRayQueryParameters3D.create(start, finish, 3, [player.get_rid()])
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider.has_meta("interaction_id") and player.global_position.distance_to(hit.position) <= 2.6:
		current_target = hit.collider.get_meta("interaction_id")
	prompt_label.text = "[ E ]  " + NAMES[current_target] if not current_target.is_empty() else ""
	crosshair.modulate = Color("e8c987") if not current_target.is_empty() else Color.WHITE

func show_dialog(title: String, message: String) -> void:
	dialog_title.text = title
	dialog_text.text = message
	dialog_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	crosshair.hide()
	dialog_panel.show()
	prompt_label.hide()

func close_dialog() -> void:
	dialog_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	crosshair.show()
	dialog_panel.hide()
	prompt_label.show()
	_update_target()
	if waking and not wake_in_progress:
		_wake_from_bed()

func _wake_from_bed() -> void:
	wake_in_progress = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	crosshair.hide()
	wake_tween = create_tween().set_parallel(true)
	wake_tween.tween_property(rabbit, "position", player.global_position, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wake_tween.tween_property(rabbit, "rotation", Vector3(0, PI, 0), 0.9)
	wake_tween.tween_property(wake_camera, "global_position", camera.global_position, 0.9)
	wake_tween.tween_property(wake_camera, "global_rotation", camera.global_rotation, 0.9)
	await wake_tween.finished
	rabbit.set_as_top_level(false)
	rabbit.position = Vector3.ZERO
	rabbit.rotation = Vector3(0, PI, 0)
	waking = false
	wake_in_progress = false
	camera.current = true
	if not dialog_open and not ended:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		crosshair.show()

func interact(id: String) -> void:
	if ended or not targets.has(id):
		return
	match id:
		"note":
			if stage == 0:
				stage = 1
				_chime(520)
			show_dialog("枕元の置き手紙", "おはようございます。帰り道は、遊園地の電話でお尋ねください。\n\n鏡に知らないお客様が映っていても、振り返らないこと。")
		"phone":
			if stage == 0:
				show_dialog("古い電話", "受話器のそばに『先に置き手紙をお読みください』とある。")
			elif stage == 1:
				stage = 2
				_chime(185)
				show_dialog("電話の向こうの声", "『……お帰りですか。鍵はお客様がお持ちです。』\n『鏡をご覧ください。目が合っても、挨拶はしないで。』\n\n通話は切れた。風が止まった。森の奥が、少し青い。")
			else:
				show_dialog("古い電話", "もう、何も聞こえない。\n受話器だけが、まだ少し温かい。")
		"mirror":
			if stage < 2:
				show_dialog("姿見", "曇った鏡。\n自分の姿は、うまく見えない。")
			elif stage == 2:
				stage = 3
				_chime(275)
				show_dialog("鏡の中のお客様", "自分とは違う、長い耳の影が立っている。\n\n鏡の内側に文字が浮かんだ。\n『あの曲が終われば、鍵をお返しします。』")
			else:
				show_dialog("姿見", "鏡の中のお客様は、オルゴールを待っている。" if stage == 3 else "鏡には、誰もいない。")
		"music":
			if stage < 3:
				show_dialog("オルゴール", "ぜんまいが動かない。\n誰かが、この曲を待っている気がする。")
			elif stage == 3:
				stage = 4
				_music_phrase()
				show_dialog("オルゴール", "短い曲が鳴って、蓋の中に小さな鍵が現れた。\n\n帰りの鍵を手に入れた。\n今度こそ、扉を開けよう。")
			else:
				show_dialog("オルゴール", "曲は終わった。\nもう一度、鳴らす必要はない。")
		"door":
			if stage < 4:
				show_dialog("森の扉", "鍵がかかっている。\n管理人の案内に従って、帰りの鍵を探そう。")
			else:
				ended = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				crosshair.hide()
				dialog_open = false
				dialog_panel.hide()
				prompt_label.hide()
				ending_panel.show()
				_chime(880)
		"window":
			show_dialog("忘れられた駅", "森の向こうに、見覚えのない駅が見える。" if stage >= 2 else "誰も乗っていない電車の窓。\n行き先には『まもなく朝』と書いてある。")
	_refresh_state()

func _refresh_state() -> void:
	objective_label.text = OBJECTIVES[stage]
	shadow_guest.visible = stage >= 2 and stage < 4
	key_mesh.visible = stage == 4
	chapter_label.text = "01  /  森のベッド" if stage < 2 else ("02  /  忘れられた遊園地" if stage < 4 else "03  /  朝への扉")
	world_environment.environment.ambient_light_color = Color("91b2aa") if stage >= 2 else Color("d8e2cb")
	world_environment.environment.ambient_light_energy = 0.38 if stage >= 2 else 0.55
	lamp.light_color = Color("a5d6ba") if stage >= 2 else Color("ffcc88")
	lamp.light_energy = 0.25 if stage >= 2 else 0.38

func restart_game() -> void:
	if wake_tween != null and wake_tween.is_running():
		wake_tween.kill()
	stage = 0
	ended = false
	elapsed = 0.0
	player.position = SPAWN_POS
	player.velocity = Vector3.ZERO
	rabbit.rotation = Vector3(0, PI, 0)
	player.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	camera_arm.rotation = Vector3(deg_to_rad(-8), 0, 0)
	ending_panel.hide()
	_refresh_state()
	_intro()
