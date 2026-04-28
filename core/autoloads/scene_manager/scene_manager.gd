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

var current_scene: Node = null
var target_scene: PackedScene = null


func _ready() -> void:
	reset_transition()


func replace_transitions_with(scene: PackedScene) -> void:
	var animation: StringName = transition_player.current_animation
	remove_child(transition_player)
	transition_player.queue_free()

	var new_transitions: AnimationPlayer = scene.instantiate()
	add_child(new_transitions)
	transition_player = new_transitions
	reset_transition()

	if not animation.is_empty():
		transition_player.play(animation)


func swap_to_path(scene_path: String) -> void:
	swap_to_packed(load(scene_path))


func swap_to_packed(scene: PackedScene) -> void:
	swap_to_node(scene.instantiate())


func swap_to_node(node: Node) -> void:
	get_tree().change_scene_to_node.call_deferred(node)
	current_scene = node
	scene_changed.emit.call_deferred()


func transition_to_file(scene_path: String) -> void:
	transition_to_packed(load(scene_path))


func transition_to_packed(scene: PackedScene) -> void:
	reset_transition()

	if (
		(not Config.get_value("interface", "scene_transitions")) or
		(not is_instance_valid(transition_player))
	):
		swap_to_packed(scene)
		return

	if is_instance_valid(current_scene):
		current_scene.process_mode = Node.PROCESS_MODE_DISABLED

	visible = true
	target_scene = scene

	transition_player.speed_scale = transition_speed_scale
	transition_player.play(&"in")


func reload_current_scene() -> void:
	reset_transition()

	if is_instance_valid(target_scene):
		swap_to_packed(target_scene)
	else:
		get_tree().reload_current_scene()
		current_scene = get_tree().current_scene


func reset_transition() -> void:
	if (
		is_instance_valid(transition_player) and
		transition_player.has_animation(&"RESET")
	):
		transition_player.play(&"RESET")

	visible = false


func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"in":
			transitioned_in.emit()
			transition_player.play(&"out")

			if is_instance_valid(target_scene):
				var node: Node = target_scene.instantiate()
				node.process_mode = Node.PROCESS_MODE_DISABLED
				swap_to_node(node)
		&"out":
			transitioned_out.emit()
			reset_transition()

			if is_instance_valid(current_scene):
				current_scene.process_mode = Node.PROCESS_MODE_INHERIT
