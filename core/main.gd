class_name ModuleHandler
extends Node


@export_group("Hardcoded Scene", "hardcoded_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var hardcoded_enabled: bool = false
@export_file("*.tscn") var hardcoded_scene_path: String


func _ready() -> void:
	if hardcoded_enabled:
		SceneManager.swap_to_packed(load(hardcoded_scene_path))
	else:
		# TODO: Actually make the softmodded module system
		SceneManager.swap_to_packed(load("res://modules/funkin/module.tscn"))
