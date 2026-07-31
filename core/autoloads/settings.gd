extends Node


var user_had_core_settings: bool

var _settings: Dictionary[StringName, Dictionary] = {}
var _default_settings: Dictionary[StringName, Dictionary] = {}

signal setting_changed(file: StringName, key: Variant)
signal settings_loaded(file: StringName)
signal settings_saved(file: StringName)

signal defaults_changed(file: StringName)


func _init() -> void:
	user_had_core_settings = has_settings(&"core")
	set_default_settings(&"core", _get_core_defaults())
	_settings[&"core"] = _default_settings[&"core"]


func _ready() -> void:
	load_settings(&"core")


func get_settings_path(file: StringName) -> String:
	return "user://%s_settings.json" % [file]


func has_settings(file: StringName) -> bool:
	var path := get_settings_path(file)
	return FileAccess.file_exists(path)


func load_settings(file: StringName) -> void:
	_settings[file] = get_default_settings(file)

	var path := get_settings_path(file)
	if not FileAccess.file_exists(path):
		settings_loaded.emit(file)
		save_settings(file)
		return

	var raw_settings := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var parse_error := json.parse(raw_settings)

	if parse_error != OK:
		printerr("Failed to parse settings '%s' with error code %s!" % [
			file,
			parse_error,
		])
		return

	if json.data is not Dictionary or json.data == null:
		push_warning("Cannot load settings of a type other than Dictionary (or one that is null).")
		return

	var settings: Dictionary = json.data as Dictionary
	for key: Variant in settings.keys():
		set_setting(file, key, settings[key], false)

	save_settings(file)

	settings_loaded.emit(file)


func set_setting(file: StringName, key: Variant, value: Variant, save: bool = true) -> void:
	var settings := get_settings(file)
	settings[key] = value
	setting_changed.emit(file, key)

	if save:
		save_settings(file)


func get_setting(file: StringName, key: Variant, default: Variant = null) -> Variant:
	var settings := get_settings(file)
	return settings.get(key, default)


func save_settings(file: StringName) -> void:
	var path := get_settings_path(file)
	var settings := get_settings(file)
	var file_access := FileAccess.open(path, FileAccess.WRITE)
	file_access.resize(0)

	var saved := file_access.store_string(JSON.stringify(settings, "    "))
	if not saved:
		printerr("Settings at path '%s' failed to save with error code %s!" % [
			path,
			file_access.get_error(),
		])
		return

	settings_saved.emit(file)


func get_settings(file: StringName) -> Dictionary:
	assert(_settings.has(file), "Settings must exist to access them.")
	return _settings[file]


func set_default_settings(file: StringName, settings: Dictionary) -> void:
	_default_settings[file] = settings
	defaults_changed.emit(file)


func get_default_settings(file: StringName) -> Dictionary:
	assert(_default_settings.has(file), "Default settings must exist to access them.")
	return _default_settings[file]


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
		"holds_below_receptors": true,

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
