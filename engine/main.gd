extends Node


@export_group("Hardcoded Scene", "hardcoded_")

## When enabled, this scene will only load the given [member hardcoded_scene_path]
## and disable mods & mod switching at the same time.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var hardcoded_enabled := false

## Path to the scene that will be loaded if [member hardcoded_enabled] is on.
@export_file("*.tscn") var hardcoded_scene_path := ""


func _enter_tree() -> void:
	if hardcoded_enabled:
		ModSwitcher.queue_free()
		SceneManager.swap_to_file(hardcoded_scene_path)
	else:
		var current_module: String = SaveData.get_save_value(&"module", "current_module")
		var target_path := "res://mods/%s/module.tscn" % current_module

		if ResourceLoader.exists(target_path):
			SceneManager.swap_to_file(target_path)
		else:
			SceneManager.swap_to_file("res://engine/fallback_screen.tscn")
