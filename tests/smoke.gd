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
	_check(not game.shadow_guest.visible and not game.key_mesh.visible, "clues begin hidden")
	_check_on_screen(game.objective_label.get_parent(), "objective panel")
	_check_on_screen(game.prompt_label, "interaction prompt")
	_check_on_screen(game.find_child("ControlsLabel", true, false), "controls label")
	game._unhandled_input(_key(KEY_ESCAPE))
	_check(not game.dialog_open, "Escape dismisses intro dialog")

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
	_check(not game.shadow_guest.visible and not game.key_mesh.visible and not game.ending_panel.visible, "restart resets visual clues")
	_check(game.player.position.distance_to(Vector3(0.5, 0.03, 2.4)) < 0.01, "restart resets player position")
	game.close_dialog()
	game.interact("door")
	_check(game.stage == 0 and not game.ended, "door is locked again after restart")
	game.close_dialog()
	game.player.position = game.targets["note"] + Vector3(0, 0.03, 1.0)
	game.camera.look_at(Vector3(-0.75, 0.90, 0.1))
	game._update_target()
	game._unhandled_input(_key(KEY_E))
	_check(game.stage == 1 and game.dialog_open, "E interacts with nearby clue")
	game._unhandled_input(_key(KEY_ENTER))
	_check(not game.dialog_open and game.stage == 1, "Enter dismisses clue dialog")

	# Interaction prompts follow proximity, and movement responds to the mapped action.
	game.player.position = game.targets["phone"] + Vector3(0, 0.03, 1.0)
	game.camera.look_at(Vector3(0.15, 1.43, -3.25))
	game._update_target()
	_check(game.current_target == "phone", "aimed nearby phone becomes current target")
	_check(game.camera.projection == Camera3D.PROJECTION_PERSPECTIVE and game.camera.get_parent() == game.player, "first-person perspective camera follows player")
	game.camera.rotation = Vector3(0, PI, 0)
	game._update_target()
	_check(game.current_target.is_empty(), "looking away removes interaction")
	game.camera.rotation = Vector3.ZERO
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120, 10000)
	game._apply_mouse_look(motion.relative)
	_check(absf(game.player.rotation.y) > 0.1, "mouse turns first-person yaw")
	_check(is_equal_approx(game.camera.rotation.x, deg_to_rad(-75)), "vertical mouse look clamps at 75 degrees")
	game.show_dialog("テスト", "会話中")
	var saved_rotation: Vector3 = game.player.rotation
	game._apply_mouse_look(motion.relative)
	_check(game.player.rotation == saved_rotation, "dialogue blocks mouse look")
	game.close_dialog()
	game.player.rotation = Vector3.ZERO
	game.camera.rotation = Vector3.ZERO
	game.player.position = Vector3(0.5, 0.03, 2.4)
	game._update_target()
	var start_position: Vector3 = game.player.position
	Input.action_press("walk_right")
	for i in range(12):
		await physics_frame
	Input.action_release("walk_right")
	_check(game.player.position.distance_to(start_position) > 0.1, "movement action moves player")
	game.player.position = Vector3(-0.9, 0.03, 1.25)
	var hit: KinematicCollision3D = game.player.move_and_collide(Vector3(0, 0, -1.5))
	_check(hit != null and game.player.position.z > 0.7, "table collision blocks passage")

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
