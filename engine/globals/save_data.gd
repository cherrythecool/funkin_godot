extends Node


var had_core_save: bool

var _saves: Dictionary[StringName, Dictionary] = {}
var _default_saves: Dictionary[StringName, Dictionary] = {}

signal save_changed(file: StringName, key: Variant)
signal save_loaded(file: StringName)
signal save_saved(file: StringName)

signal defaults_changed(file: StringName)


func _ready() -> void:
	had_core_save = has_save(&"core")
	set_default_save(&"core", _get_core_defaults())
	load_save(&"core")


func get_saves_path(file: StringName) -> String:
	return "user://%s_save.json" % [file]


func has_save(file: StringName) -> bool:
	var path := get_saves_path(file)
	return FileAccess.file_exists(path)


func load_save(file: StringName) -> void:
	_saves[file] = get_default_save(file)

	var path := get_saves_path(file)
	if not FileAccess.file_exists(path):
		save_loaded.emit(file)
		save(file)
		return

	var raw_saves := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var parse_error := json.parse(raw_saves)

	if parse_error != OK:
		printerr("Failed to parse saves '%s' with error code %s!" % [
			file,
			parse_error,
		])
		return

	if json.data is not Dictionary or json.data == null:
		push_warning("Cannot load saves of a type other than Dictionary (or one that is null).")
		return

	var saves: Dictionary = json.data as Dictionary
	for key: Variant in saves.keys():
		set_save_value(file, key, saves[key], false)

	save(file)
	save_loaded.emit(file)


func set_save_value(file: StringName, key: Variant, value: Variant, save_: bool = true) -> void:
	var saves := get_save(file)
	saves[key] = value
	save_changed.emit(file, key)

	if save_:
		save(file)


func get_save_value(file: StringName, key: Variant, default: Variant = null) -> Variant:
	var saves := get_save(file)
	return saves.get(key, default)


func save(file: StringName) -> void:
	var path := get_saves_path(file)
	var saves := get_save(file)
	var file_access := FileAccess.open(path, FileAccess.WRITE)
	file_access.resize(0)

	var saved := file_access.store_string(JSON.stringify(saves, "    "))
	if not saved:
		printerr("saves at path '%s' failed to save with error code %s!" % [
			path,
			file_access.get_error(),
		])
		return

	save_saved.emit(file)


func get_save(file: StringName) -> Dictionary:
	assert(_saves.has(file), "saves must exist to access them.")
	return _saves[file]


func set_default_save(file: StringName, saves: Dictionary) -> void:
	_default_saves[file] = saves
	defaults_changed.emit(file)


func get_default_save(file: StringName) -> Dictionary:
	assert(_default_saves.has(file), "Default saves must exist to access them.")
	return _default_saves[file]


func _get_core_defaults() -> Dictionary:
	var core_defaults := {
		"volume": {
			"Master": 0.1,
			"Music": 1.0,
			"SFX": 1.0,
		},

		"controls_keybinds": {
			"note_left": [KEY_LEFT, KEY_D],
			"note_down": [KEY_DOWN, KEY_F],
			"note_up": [KEY_UP, KEY_J],
			"note_right": [KEY_RIGHT, KEY_K],

			"menu_left": [KEY_LEFT, KEY_A],
			"menu_down": [KEY_DOWN, KEY_S],
			"menu_up": [KEY_UP, KEY_W],
			"menu_right": [KEY_RIGHT, KEY_D],

			"menu_cancel": [KEY_ESCAPE, KEY_BACKSPACE],
			"menu_accept": [KEY_ENTER, KEY_SPACE],

			"menu_fullscreen": [KEY_F11],
			"module_select": [KEY_F9],

			"game_pause": [KEY_ENTER, KEY_ESCAPE],
		},

		"downscroll": false,
		"middlescroll": false,

		"note_offset": 0.0,
		"note_scroll_method": "chart_multiplier",
		"note_scroll_value": 1.0,
		"note_underlay_alpha": 0.0,
		"note_splash_alpha": 0.8,

		"rating_alpha": 1.0,
		"time_bar_show": true,
		"skip_scene_transitions": false,

		"performance_mode": false,
		"pause_when_unfocused": true,
		"max_fps": 0.0,
		"vsync_enabled": false,
		"scale_with_dpi": true,

		"overlay_visible": false,
		# TODO: add more options / customization to this
		"overlay_mode": "minimal",

		"flashing_lights": true,

		# TODO: actually implement this
		"language": "en_US",
	}

	# Non desktop platforms generally don't work so well
	# with vsync disabled, *and* usually have their own
	# way of scaling the screen (often fullscreen too).
	if not OS.has_feature("pc"):
		core_defaults["scale_with_dpi"] = false
		core_defaults["vsync_enabled"] = true
	else:
		# 240 is a fairly okay framerate for most systems and if you have
		# a higher refresh rate than it then you can probably handle a lot more
		# lol.
		var refresh_rate: float = DisplayServer.screen_get_refresh_rate()
		if refresh_rate > 240.0:
			core_defaults["max_fps"] = refresh_rate
		else:
			core_defaults["max_fps"] = 240.0

	return core_defaults
