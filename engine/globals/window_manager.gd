extends Node

static var window_prefix:String = ""
static var window_name:String = ""
static var window_suffix:String = ""

static var window_icon:Image = load("res://engine/default_icon.png")

static var should_update_window:bool = true

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

static func reset_window() -> void:
	var old_should_update_window: bool = should_update_window
	
	should_update_window = false
	
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
	
	should_update_window = old_should_update_window
	
	update_window()

static func update_window() -> void:
	if should_update_window:
		DisplayServer.window_set_title(window_prefix + window_name + window_suffix)
		DisplayServer.set_icon(window_icon)
