extends Node3D
## Original procedural short horror prototype. No third-party game assets.
var stage: int = 0
var ended: bool = false
var dialog_open: bool = false
var current_target: String = ""
var player: CharacterBody3D
var rabbit: Node3D
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
const OBJECTIVES: Array[String] = ["机の置き手紙を読む", "電話で管理人に連絡する", "鏡を調べる", "オルゴールを調べる", "鍵を持って、扉から帰る"]
const NAMES: Dictionary = {"note": "置き手紙", "phone": "古い電話", "mirror": "姿見", "music": "オルゴール", "door": "出口の扉", "window": "窓"}

func _ready() -> void:
	_setup_inputs()
	_build_materials()
	_build_room()
	_build_player()
	_build_lighting()
	_build_ui()
	_build_audio()
	_refresh_state()
	_intro()

func _intro() -> void:
	show_dialog("旅のしおり", "雨が止むまで、この貸別荘で休むことにした。\n\n管理人は留守らしい。まずは机の置き手紙を読もう。")

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

func _build_room() -> void:
	box(self, Vector3(0, -0.18, 0), Vector3(10, 0.35, 8), "darkwood", true)
	for z in range(16):
		for x in range(5):
			var offset := 0.10 if z % 2 == 0 else -0.10
			box(self, Vector3(-4 + x * 2 + offset, 0.008, -3.75 + z * 0.5), Vector3(1.97, 0.018, 0.48), "floor")
	box(self, Vector3(0, 1.9, -4), Vector3(10.2, 3.8, 0.2), "wall", true)
	box(self, Vector3(-5, 1.9, 0), Vector3(0.2, 3.8, 8), "wall", true)
	box(self, Vector3(0, 0.2, -3.86), Vector3(10, 0.4, 0.08), "trim")
	box(self, Vector3(-4.86, 0.2, 0), Vector3(0.08, 0.4, 8), "trim")
	for x in range(11):
		box(self, Vector3(-5 + x, 1.3, -3.86), Vector3(0.018, 1.9, 0.015), "trim")
	box(self, Vector3(-0.4, 0.03, 0.6), Vector3(4.1, 0.035, 3.2), "rug")
	for z in [-0.85, 2.05]:
		box(self, Vector3(-0.4, 0.06, z), Vector3(3.9, 0.015, 0.08), "rugline")
	for x in [-2.3, 1.5]:
		box(self, Vector3(x, 0.06, 0.6), Vector3(0.08, 0.015, 2.9), "rugline")
	box(self, Vector3(-3.8, 0.4, 0.3), Vector3(1.35, 0.75, 2.8), "sofa", true)
	box(self, Vector3(-4.4, 0.9, 0.3), Vector3(0.22, 1.4, 2.8), "sofa")
	for z in [-0.98, 1.58]:
		box(self, Vector3(-3.8, 0.8, z), Vector3(1.4, 0.4, 0.25), "sofa")
	for z in [-0.35, 0.85]:
		box(self, Vector3(-3.75, 0.82, z), Vector3(0.98, 0.14, 1.06), "pink")
	box(self, Vector3(-0.9, 0.74, 0.0), Vector3(1.9, 0.15, 1.25), "wood", true)
	for x in [-1.65, -0.15]:
		for z in [-0.42, 0.42]:
			box(self, Vector3(x, 0.35, z), Vector3(0.12, 0.7, 0.12), "darkwood")
	box(self, Vector3(-0.75, 0.833, 0.1), Vector3(0.55, 0.025, 0.4), "paper")
	for z in [0.0, 0.09, 0.18]:
		box(self, Vector3(-0.75, 0.85, z), Vector3(0.35, 0.009, 0.012), "wood")
	cylinder(self, Vector3(-1.48, 0.94, -0.15), 0.13, 0.22, "cream")
	targets["note"] = Vector3(-0.9, 0, 0.0)
	box(self, Vector3(0.1, 0.6, -3.35), Vector3(1.9, 1.2, 0.85), "wood", true)
	for x in [-0.4, 0.6]:
		box(self, Vector3(x, 0.55, -2.9), Vector3(0.82, 0.92, 0.045), "darkwood")
		sphere(self, Vector3(x, 0.66, -2.86), 0.045, "brass")
	box(self, Vector3(0.15, 1.28, -3.25), Vector3(0.65, 0.16, 0.45), "black")
	cylinder(self, Vector3(0.15, 1.38, -3.18), 0.15, 0.025, "brass")
	box(self, Vector3(0.15, 1.48, -3.42), Vector3(0.78, 0.12, 0.14), "black")
	for x in [-0.18, 0.48]:
		sphere(self, Vector3(x, 1.45, -3.42), 0.13, "black")
	targets["phone"] = Vector3(0.1, 0, -3.0)
	box(self, Vector3(0.0, 2.75, -3.84), Vector3(1.65, 0.98, 0.08), "brass")
	box(self, Vector3(0.0, 2.75, -3.78), Vector3(1.45, 0.79, 0.03), "rug")
	box(self, Vector3(0.0, 2.57, -3.75), Vector3(1.35, 0.28, 0.02), "trim")
	sphere(self, Vector3(0.4, 2.92, -3.73), 0.16, "paper", Vector3(1, 1, 0.1))
	box(self, Vector3(2.65, 1.5, -3.7), Vector3(1.25, 2.5, 0.17), "darkwood", true)
	box(self, Vector3(2.65, 1.5, -3.59), Vector3(1.02, 2.25, 0.03), "glass")
	targets["mirror"] = Vector3(2.65, 0, -3.2)
	shadow_guest = Node3D.new()
	add_child(shadow_guest)
	shadow_guest.position = Vector3(2.65, 0.55, -3.54)
	sphere(shadow_guest, Vector3(0, 0.45, 0), 0.27, "shadow", Vector3(0.8, 1.7, 0.11))
	sphere(shadow_guest, Vector3(0, 1.0, 0), 0.20, "shadow", Vector3(1, 1, 0.1))
	for x in [-0.11, 0.11]:
		sphere(shadow_guest, Vector3(x, 1.42, 0), 0.09, "shadow", Vector3(0.6, 3.4, 0.15))
	box(self, Vector3(-3.55, 0.6, -2.8), Vector3(1.5, 1.2, 0.8), "wood", true)
	box(self, Vector3(-3.55, 1.3, -2.8), Vector3(0.6, 0.22, 0.4), "darkwood")
	box(self, Vector3(-3.55, 1.46, -2.99), Vector3(0.63, 0.15, 0.08), "brass")
	cylinder(self, Vector3(-3.55, 1.48, -2.78), 0.17, 0.035, "brass")
	targets["music"] = Vector3(-3.55, 0, -2.45)
	key_mesh = Node3D.new()
	add_child(key_mesh)
	key_mesh.position = Vector3(-3.55, 1.58, -2.75)
	cylinder(key_mesh, Vector3.ZERO, 0.08, 0.025, "brass")
	box(key_mesh, Vector3(0.14, 0, 0), Vector3(0.24, 0.03, 0.045), "brass")
	box(key_mesh, Vector3(0.22, 0, 0.06), Vector3(0.045, 0.03, 0.12), "brass")
	box(self, Vector3(4.3, 1.45, -3.77), Vector3(1.25, 2.9, 0.14), "cream", true)
	box(self, Vector3(4.3, 1.42, -3.66), Vector3(1.04, 2.72, 0.08), "darkwood")
	for y in [0.75, 1.9]:
		box(self, Vector3(4.3, y, -3.60), Vector3(0.77, 0.80, 0.035), "wood")
	sphere(self, Vector3(4.65, 1.2, -3.53), 0.07, "brass")
	targets["door"] = Vector3(4.2, 0, -3.0)
	box(self, Vector3(-4.85, 2.3, -1.0), Vector3(0.07, 1.6, 1.8), "cream")
	box(self, Vector3(-4.79, 2.3, -1.0), Vector3(0.03, 1.37, 1.57), "glass")
	box(self, Vector3(-4.75, 2.3, -1.0), Vector3(0.04, 1.45, 0.05), "cream")
	box(self, Vector3(-4.75, 2.3, -1.0), Vector3(0.04, 0.05, 1.6), "cream")
	for z in [-2.0, 0.0]:
		box(self, Vector3(-4.65, 2.2, z), Vector3(0.16, 2.0, 0.32), "rugline")
	targets["window"] = Vector3(-4.15, 0, -1.0)
	cylinder(self, Vector3(-2.65, 0.06, -1.75), 0.30, 0.10, "black")
	cylinder(self, Vector3(-2.65, 1.0, -1.75), 0.035, 1.9, "brass")
	var shade := cylinder(self, Vector3(-2.65, 2.0, -1.75), 0.42, 0.48, "paper")
	(shade.mesh as CylinderMesh).top_radius = 0.22
	cylinder(self, Vector3(3.7, 0.28, 1.8), 0.3, 0.55, "sofa")
	for i in range(7):
		var angle := i * TAU / 7.0
		sphere(self, Vector3(3.7 + cos(angle) * 0.2, 0.7 + (i % 3) * 0.17, 1.8 + sin(angle) * 0.2), 0.22, "trim", Vector3(0.65, 1.8, 0.65))
	box(self, Vector3(1.8, 0.28, 2.65), Vector3(0.8, 0.55, 0.4), "coat", true)
	box(self, Vector3(1.8, 0.60, 2.65), Vector3(0.30, 0.09, 0.10), "brass")

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Traveler"
	add_child(player)
	player.position = Vector3(0.5, 0.03, 2.4)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 1.1
	collision.shape = capsule
	collision.position.y = 0.56
	player.add_child(collision)
	rabbit = Node3D.new()
	player.add_child(rabbit)
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
	environment.background_color = Color("172124")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c7c5ad")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("c3d3cb")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	lamp = OmniLight3D.new()
	add_child(lamp)
	lamp.position = Vector3(-2.65, 1.90, -1.75)
	lamp.light_color = Color("ffcc88")
	lamp.light_energy = 1.8
	lamp.omni_range = 7.0
	lamp.shadow_enabled = true
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(10, 11, 14)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.9
	camera.look_at(Vector3(-0.1, 0.9, -0.4))
	camera.current = true

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
	shader.code = "shader_type canvas_item; uniform sampler2D screen_texture : hint_screen_texture, filter_nearest; void fragment(){ vec2 uv=SCREEN_UV; vec3 c=texture(screen_texture,uv).rgb; float vignette=1.0-0.36*pow(length((uv-0.5)*1.4),2.0); float grain=fract(sin(dot(floor(uv*vec2(1100.0,720.0)),vec2(12.9898,78.233))+floor(TIME*8.0))*43758.5453)-0.5; c=floor(c*40.0)/40.0; COLOR=vec4(c*vignette+grain*0.025,1.0); }"
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	film.material = shader_material
	var header := VBoxContainer.new()
	root.add_child(header)
	header.position = Vector2(36, 27)
	header.add_theme_constant_override("separation", 5)
	header.add_child(_label("THE BORROWED ROOM", 12, Color("b7b6a0")))
	header.add_child(_label("かえりの鍵", 29, Color("efe4cc")))
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
	var controls := _label("WASD / 矢印：歩く     E / Enter：調べる     M：音の切替", 13, Color("a4b0a7"))
	controls.name = "ControlsLabel"
	root.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.offset_left = 36
	controls.offset_top = -36
	controls.offset_right = 760
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
	for item in [["CHECK OUT", 14], ["かえりの鍵", 42], ["雨は止んでいた。\n\n借りたのは、部屋だったのだろうか。\nそれとも、帰り道だったのだろうか。", 20], ["END  /  雨上がり", 15], ["R：もう一度遊ぶ", 16]]:
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
	for i in range(22050 * 3):
		var t := float(i) / 22050.0
		_sample(data, rng.randf_range(-0.065, 0.065) + sin(t * TAU * 65.0) * 0.025)
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

func _unhandled_input(event: InputEvent) -> void:
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
	if event.is_action_pressed("interact") and not current_target.is_empty():
		interact(current_target)

func _physics_process(delta: float) -> void:
	elapsed += delta
	if stage >= 2 and not ended:
		lamp.light_energy = 0.65 + sin(elapsed * 11.0) * 0.08 + sin(elapsed * 27.0) * 0.04
	if ended or dialog_open:
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
	player.position.x = clampf(player.position.x, -4.5, 4.65)
	player.position.z = clampf(player.position.z, -3.55, 3.5)
	if direction.length_squared() > 0.01:
		rabbit.rotation.y = lerp_angle(rabbit.rotation.y, atan2(direction.x, direction.z), delta * 12.0)
		rabbit.position.y = abs(sin(elapsed * 10.0)) * 0.055
	else:
		rabbit.position.y = sin(elapsed * 2.0) * 0.012
	_update_target()

func _update_target() -> void:
	current_target = ""
	var nearest := 1.55
	for id in targets:
		var point: Vector3 = targets[id]
		var distance := Vector2(player.position.x - point.x, player.position.z - point.z).length()
		if distance < nearest:
			nearest = distance
			current_target = id
	prompt_label.text = "[ E ]  " + NAMES[current_target] if not current_target.is_empty() else ""

func show_dialog(title: String, message: String) -> void:
	dialog_title.text = title
	dialog_text.text = message
	dialog_open = true
	dialog_panel.show()
	prompt_label.hide()

func close_dialog() -> void:
	dialog_open = false
	dialog_panel.hide()
	prompt_label.show()
	_update_target()

func interact(id: String) -> void:
	if ended or not targets.has(id):
		return
	match id:
		"note":
			if stage == 0:
				stage = 1
				_chime(520)
			show_dialog("管理人の置き手紙", "ようこそ。お帰りの際は、机の電話でご連絡ください。\n\n鏡に知らないお客様が映っていても、振り返らないこと。")
		"phone":
			if stage == 0:
				show_dialog("古い電話", "受話器のそばに『先に置き手紙をお読みください』とある。")
			elif stage == 1:
				stage = 2
				_chime(185)
				show_dialog("電話の向こうの声", "『……お帰りですか。鍵はお客様がお持ちです。』\n『鏡をご覧ください。目が合っても、挨拶はしないで。』\n\n通話は切れた。部屋の空気が、少し冷たい。")
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
				show_dialog("出口の扉", "鍵がかかっている。\n管理人の案内に従って、帰りの鍵を探そう。")
			else:
				ended = true
				dialog_open = false
				dialog_panel.hide()
				prompt_label.hide()
				ending_panel.show()
				_chime(880)
		"window":
			show_dialog("雨の窓", "さっきまで見えていた道が、見えなくなっている。" if stage >= 2 else "細い雨が、窓をたたいている。\n道の向こうは、霧でよく見えない。")
	_refresh_state()

func _refresh_state() -> void:
	objective_label.text = OBJECTIVES[stage]
	shadow_guest.visible = stage >= 2 and stage < 4
	key_mesh.visible = stage == 4
	chapter_label.text = "01  /  雨宿り" if stage < 2 else ("02  /  もう一人のお客様" if stage < 4 else "03  /  チェックアウト")
	world_environment.environment.ambient_light_color = Color("91b2aa") if stage >= 2 else Color("c7c5ad")
	world_environment.environment.ambient_light_energy = 0.42 if stage >= 2 else 0.65
	lamp.light_color = Color("a5d6ba") if stage >= 2 else Color("ffcc88")
	lamp.light_energy = 0.7 if stage >= 2 else 1.8

func restart_game() -> void:
	stage = 0
	ended = false
	elapsed = 0.0
	player.position = Vector3(0.5, 0.03, 2.4)
	player.velocity = Vector3.ZERO
	rabbit.rotation = Vector3.ZERO
	ending_panel.hide()
	_refresh_state()
	_intro()
