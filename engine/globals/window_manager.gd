extends Node

static var window_prefix:String = ""
static var window_name:String = ""
static var window_suffix:String = ""

static var window_icon:Image = load("res://engine/default_icon.png")

static var should_update_window:bool = true

static func reset_window() -> void:
	window_prefix = ""
	window_suffix = ""
	
	if Main.mod_meta == null or Main.mod_meta.window_title == null or Main.mod_meta.window_title == "":
		window_name = ProjectSettings.get_setting("application/config/name", "Friday Night Funkin'")
	else:
		window_name = Main.mod_meta.window_title
		
	if Main.mod_meta == null or Main.mod_meta.window_icon == null or !ResourceLoader.exists(Main.mod_meta.window_icon):
		window_icon = load("res://engine/default_icon.png")
	else:
		window_icon = load(Main.mod_meta.window_icon)
		
	update_window()

static func update_window() -> void:
	if should_update_window:
		DisplayServer.window_set_title(window_prefix + window_name + window_suffix)
		DisplayServer.set_icon(window_icon)
