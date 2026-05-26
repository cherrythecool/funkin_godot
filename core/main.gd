class_name ModuleLoader
extends Node


@export_group("Hardcoded Scene", "hardcoded_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var hardcoded_enabled := false
@export_file("*.tscn") var hardcoded_scene_path := ""


func _ready() -> void:
	if hardcoded_enabled:
		SceneManager.swap_to_path(hardcoded_scene_path)
	else:
		var current_module: String = Settings.get_setting(&"module", "current_module")
		var target_path := "res://modules/%s/module.tscn" % current_module

		if ResourceLoader.exists(target_path):
			SceneManager.swap_to_path(target_path)
		else:
			SceneManager.swap_to_path("res://core/fallback_screen.tscn")
