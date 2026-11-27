class_name ModManager extends Node


@export_group("Hardcoded Scene", "hardcoded_")

## When enabled, this scene will only load the given [member hardcoded_scene_path]
## and disable mods & mod switching at the same time.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var hardcoded_enabled := false

## Path to the scene that will be loaded if [member hardcoded_enabled] is on.
@export_file("*.tscn") var hardcoded_scene_path := ""

@export_group("Misc")
@export var default_mod_meta:ModMetaData = ModMetaData.new()

static var mod_meta:ModMetaData

func _enter_tree() -> void:
	if hardcoded_enabled:
		ModSwitcher.queue_free()
		SceneManager.swap_to_file(hardcoded_scene_path)
	else:
		await ready

		var current_module: String = SaveData.get_save_value(&"module", "current_module")
		var target_path := "res://mods/%s/module.tscn" % current_module
		
		if ResourceLoader.exists("res://mods/%s/meta.tres" % current_module):
			mod_meta = load("res://mods/%s/meta.tres" % current_module)
		else:
			mod_meta = default_mod_meta
		
		if ResourceLoader.exists(target_path):
			SceneManager.swap_to_file(target_path)
		else:
			SceneManager.swap_to_file("res://engine/fallback_screen.tscn")
			
		update_window()

# Window Stuff


var window_prefix:String = ""
var window_name:String = ""
var window_suffix:String = ""
var window_icon:Image = load("res://engine/default_icon.png")

var should_update_window:bool = true

var old_window_prefix:String = ""
var old_window_name:String = ""
var old_window_suffix:String = ""

var old_window_icon:Image

func _process(_delta: float) -> void:
	if old_window_icon != window_icon or old_window_name != window_name or old_window_prefix != window_prefix or old_window_suffix != window_suffix:
		old_window_icon = window_icon
		old_window_prefix = window_prefix
		old_window_name = window_name
		old_window_suffix = window_suffix
		
		update_window()

func reset_window() -> void:
	var old_should_update_window: bool = should_update_window
	
	should_update_window = false
	
	window_prefix = ""
	window_suffix = ""
	
	if mod_meta == null or mod_meta.window_title == null or mod_meta.window_title == "":
		window_name = ProjectSettings.get_setting("application/config/name", "Friday Night Funkin'")
	else:
		window_name = mod_meta.window_title
		
	if mod_meta == null or mod_meta.window_icon == null or !ResourceLoader.exists(mod_meta.window_icon):
		window_icon = load("res://engine/default_icon.png")
	else:
		window_icon = load(mod_meta.window_icon)
	
	should_update_window = old_should_update_window
	
	update_window()

func update_window() -> void:
	if should_update_window:
		DisplayServer.window_set_title(window_prefix + window_name + window_suffix)
		DisplayServer.set_icon(window_icon)
