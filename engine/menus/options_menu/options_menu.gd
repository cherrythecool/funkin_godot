extends Control


var target_scene: String = ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"menu_cancel"):
		SceneManager.transition_to_file(target_scene)
