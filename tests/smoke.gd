extends SceneTree

var failures := 0
var checks := 0

func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event

func _check_on_screen(control: Control, description: String) -> void:
	if control == null:
		_check(false, description + " exists")
		return
	var area := control.get_global_rect()
	var view_size := Vector2(1100, 720)
	_check(area.position.x >= 0 and area.position.y >= 0 and area.end.x <= view_size.x and area.end.y <= view_size.y, description + " fits viewport")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	_check(scene != null, "main scene loads")
	if scene == null:
		quit(1)
		return
	var game: Node3D = scene.instantiate()
	root.add_child(game)
	await physics_frame
	await process_frame
	_check(game.stage == 0 and not game.ended, "initial story state")
	_check(game.dialog_open, "intro dialog opens")
	var sun: DirectionalLight3D = game.get_node("OvercastSun")
	_check(sun.shadow_enabled and sun.light_angular_distance > 0.5, "sun has soft angular shadows")
	_check(game.world_environment.environment.sky != null, "overcast sky provides ambient lighting")
	_check(game.materials["brass"].roughness < game.materials["blanket"].roughness, "metal and cloth have distinct roughness")
	var canopy_count := 0
	for child in game.get_children():
		if child.has_meta("leaf_shadow_canopy"):
			canopy_count += 1
	_check(canopy_count == 4, "leaf cutout canopy supplies dappled shadows")
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		_check(game.world_environment.environment.ssao_enabled and game.world_environment.environment.ssil_enabled and game.world_environment.environment.volumetric_fog_enabled, "Forward+ enables contact shading, bounced light and volumetric fog")
	else:
		_check(not game.world_environment.environment.ssao_enabled and not game.world_environment.environment.ssil_enabled and not game.world_environment.environment.volumetric_fog_enabled, "Compatibility disables unsupported advanced effects")
	_check(game.waking and game.wake_camera.current and game.bed != null, "story begins waking in forest bed")
	_check(game.rabbit.is_set_as_top_level(), "opening character lies on bed")
	var sleeping_position: Vector3 = game.player.position
	Input.action_press("walk_up")
	await physics_frame
	Input.action_release("walk_up")
	_check(game.player.position == sleeping_position, "opening blocks walking before waking")
	_check(not game.shadow_guest.visible and not game.key_mesh.visible, "clues begin hidden")
	_check_on_screen(game.objective_label.get_parent(), "objective panel")
	_check_on_screen(game.prompt_label, "interaction prompt")
	_check_on_screen(game.find_child("ControlsLabel", true, false), "controls label")
	game._unhandled_input(_key(KEY_ESCAPE))
	_check(not game.dialog_open, "Escape dismisses intro dialog")
	await create_timer(1.1).timeout
	_check(not game.waking and not game.wake_in_progress and game.camera.current, "waking transitions to third-person exploration")
	_check(not game.rabbit.is_set_as_top_level() and game.rabbit.visible, "traveler stands beside forest bed")

	game.interact("door")
	_check(game.stage == 0 and not game.ended, "door blocks exit before key")
	game.close_dialog()
	game.interact("phone")
	_check(game.stage == 0, "phone cannot skip the note")
	game.close_dialog()
	game.interact("mirror")
	_check(game.stage == 0, "mirror cannot skip the phone")
	game.close_dialog()
	game.interact("music")
	_check(game.stage == 0, "music box cannot skip the clues")
	game.close_dialog()
	game.interact("unknown")
	_check(game.stage == 0 and not game.dialog_open, "unknown target has no effect")

	game.interact("note")
	_check(game.stage == 1 and game.dialog_open, "reading note advances story")
	game.close_dialog()
	game.interact("note")
	_check(game.stage == 1, "revisiting note does not advance story")
	game.close_dialog()
	game.interact("music")
	_check(game.stage == 1, "music box remains blocked before mirror")
	game.close_dialog()
	game.interact("phone")
	_check(game.stage == 2 and game.shadow_guest.visible, "phone reveals the visitor")
	game.close_dialog()
	game.interact("door")
	_check(game.stage == 2 and not game.ended, "door remains locked after phone")
	game.close_dialog()
	game.interact("mirror")
	_check(game.stage == 3 and game.shadow_guest.visible, "mirror reveals music clue")
	game.close_dialog()
	game.interact("music")
	_check(game.stage == 4 and game.key_mesh.visible and not game.shadow_guest.visible, "music box yields key")
	game.close_dialog()
	game.interact("music")
	_check(game.stage == 4 and not game.ended, "revisiting music box does not end game")
	game.close_dialog()
	game.interact("door")
	_check(game.ended and not game.dialog_open and game.ending_panel.visible, "key unlocks ending")
	game.interact("note")
	_check(game.ended and game.stage == 4, "ending ignores further interactions")

	game._unhandled_input(_key(KEY_R))
	_check(game.stage == 0 and not game.ended and game.dialog_open, "restart resets story and intro")
	_check(game.waking and game.wake_camera.current, "restart returns to bed awakening")
	_check(not game.shadow_guest.visible and not game.key_mesh.visible and not game.ending_panel.visible, "restart resets visual clues")
	_check(game.player.position.distance_to(game.SPAWN_POS) < 0.01, "restart resets player position")
	game.close_dialog()
	game.interact("door")
	_check(game.stage == 0 and not game.ended, "door is locked again after restart")
	game.close_dialog()
	await create_timer(1.1).timeout
	game.player.position = game.targets["note"] + Vector3(0, 0.03, 1.0)
	game.camera.look_at(game.interaction_centers["note"])
	game._update_target()
	game._unhandled_input(_key(KEY_E))
	_check(game.stage == 1 and game.dialog_open, "E interacts with nearby clue")
	game._unhandled_input(_key(KEY_ENTER))
	_check(not game.dialog_open and game.stage == 1, "Enter dismisses clue dialog")

	# Interaction prompts follow proximity, and movement responds to the mapped action.
	game.player.position = game.targets["phone"] + Vector3(0, 0.03, 1.0)
	game.camera.look_at(game.interaction_centers["phone"])
	game._update_target()
	_check(game.current_target == "phone", "aimed nearby phone becomes current target")
	_check(game.camera.projection == Camera3D.PROJECTION_PERSPECTIVE and game.camera.get_parent() == game.camera_arm and game.camera_arm.get_parent() == game.player and game.rabbit.visible, "third-person camera follows visible player")
	game.camera.rotation = Vector3(0, PI, 0)
	game._update_target()
	_check(game.current_target.is_empty(), "looking away removes interaction")
	game.camera.rotation = Vector3.ZERO
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120, 10000)
	if DisplayServer.get_name() == "headless":
		game._apply_mouse_look(motion.relative)
	else:
		game._unhandled_input(motion)
	_check(absf(game.player.rotation.y) > 0.1, "mouse turns third-person yaw")
	_check(is_equal_approx(game.camera_arm.rotation.x, deg_to_rad(-55)), "vertical mouse look clamps at 55 degrees")
	game.show_dialog("テスト", "会話中")
	var saved_rotation: Vector3 = game.player.rotation
	game._apply_mouse_look(motion.relative)
	_check(game.player.rotation == saved_rotation, "dialogue blocks mouse look")
	game.close_dialog()
	game.player.rotation = Vector3.ZERO
	game.camera.rotation = Vector3.ZERO
	game.player.position = game.SPAWN_POS
	game._update_target()
	var start_position: Vector3 = game.player.position
	Input.action_press("walk_right")
	for i in range(12):
		await physics_frame
	Input.action_release("walk_right")
	_check(game.player.position.distance_to(start_position) > 0.1, "movement action moves player")
	for id in ["note", "phone", "mirror", "music", "door"]:
		var found := false
		for offset in [Vector3(0, 0.03, 1.3), Vector3(1.3, 0.03, 0), Vector3(-1.3, 0.03, 0)]:
			game.player.position = game.targets[id] + offset
			game.player.velocity = Vector3.ZERO
			await physics_frame
			game.camera.look_at(game.interaction_centers[id])
			game._update_target()
			if game.current_target == id:
				found = true
				break
		_check(found, "forest target can be aimed and inspected: " + id)
	game.camera.rotation = Vector3.ZERO
	game.player.rotation = Vector3.ZERO
	var obstacle: MeshInstance3D = game.box(game, Vector3(0, 1.9, 9), Vector3(3, 3, 0.2), "mint", true)
	game.player.position = Vector3(0, 0.03, 7.6)
	game.player.velocity = Vector3.ZERO
	game.camera_arm.rotation = Vector3.ZERO
	for i in range(4):
		await physics_frame
	_check(game.camera_arm.get_hit_length() < game.camera_arm.spring_length, "camera retracts at obstacles")
	_check(game.camera.global_position.z < 8.9, "camera stays before obstacle")
	obstacle.queue_free()
	game.player.position = Vector3(0, 0.03, 6.8)
	var hit: KinematicCollision3D = game.player.move_and_collide(Vector3(0, 0, -2.0))
	_check(hit != null and game.player.position.z > 5.3, "forest bed blocks passage")

	print("Smoke test: %d checks, %d failures" % [checks, failures])
	game.ambience.stop()
	game.tone.stop()
	game.ambience.stream = null
	game.tone.stream = null
	await create_timer(0.25).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures > 0 else 0)
