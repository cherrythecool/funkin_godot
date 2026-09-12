extends CanvasLayer


signal scene_changed
signal transitioned_in
signal transitioned_out

@export_group("Transition", "transition_")
@export var transition_player: AnimationPlayer = null:
	set(value):
		if is_instance_valid(transition_player):
			transition_player.animation_finished.disconnect(_on_animation_finished)

		transition_player = value

		if is_instance_valid(transition_player):
			transition_player.animation_finished.connect(_on_animation_finished)

@export_range(0.0, 5.0, 0.01, "or_greater") var transition_speed_scale: float = 1.0

var current_scene: Node = null:
	get:
		if is_inside_tree() and not is_instance_valid(current_scene):
			current_scene = get_tree().current_scene

		return current_scene

var _target_scene_path := ""


func _ready() -> void:
	_reset_transition()


func transition_to_file(scene_path: String) -> void:
	_reset_transition()

	if Settings.get_setting(&"core", "skip_scene_transitions") or not is_instance_valid(transition_player):
		swap_to_file(scene_path)
		return

	_target_scene_path = scene_path

	if is_instance_valid(current_scene):
		current_scene.process_mode = Node.PROCESS_MODE_DISABLED

	visible = true
	_play_animation(&"in")


func swap_to_file(scene_path: String) -> void:
	_target_scene_path = scene_path
	get_tree().change_scene_to_file.call_deferred(scene_path)
	scene_changed.emit.call_deferred()


func reload_current_scene() -> void:
	_reset_transition()

	if ResourceLoader.exists(_target_scene_path, "PackedScene") and not _target_scene_path.is_empty():
		swap_to_file(_target_scene_path)
	else:
		get_tree().reload_current_scene()
		current_scene = get_tree().current_scene


func replace_transitions_with(scene: PackedScene) -> void:
	var animation: StringName = transition_player.current_animation if transition_player else &""

	if transition_player:
		remove_child(transition_player)
		transition_player.queue_free()

	var new_transitions := scene.instantiate() as AnimationPlayer
	transition_player = new_transitions
	add_child(new_transitions)
	_reset_transition()

	if not animation.is_empty():
		transition_player.play(animation)


func _play_animation(anim: StringName) -> void:
	if is_instance_valid(transition_player) and transition_player.has_animation(anim):
		transition_player.speed_scale = transition_speed_scale
		transition_player.play(anim)


func _reset_transition() -> void:
	visible = false
	_play_animation(&"RESET")


func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"in":
			transitioned_in.emit()
			_play_animation(&"out")
			swap_to_file(_target_scene_path)
		&"out":
			transitioned_out.emit()
			_reset_transition()
