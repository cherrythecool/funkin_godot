extends Node


const CONFIG_PATH: String = "user://config.cfg"

var had_user_config: bool = false
var _file: ConfigFile = ConfigFile.new()
var _default_configuration: Dictionary

signal loaded
signal saved
signal value_changed(section: String, key: String, value: Variant)


func _ready() -> void:
	_setup_default_configuration()
	_file = _create_config_with_defaults()
	_load_user_config()

	save()
	loaded.emit()


func get_value(section: String, key: String) -> Variant:
	return _file.get_value(section, key)


func set_value(section: String, key: String, value: Variant, autosave: bool = true) -> void:
	_file.set_value(section, key, value)
	value_changed.emit(section, key, value)

	if autosave:
		save()


func save() -> void:
	var error: Error = _file.save(CONFIG_PATH)
	if error == OK:
		saved.emit()
	else:
		push_error("Failed to save config with error code: %d" % [error,])


func get_vsync_mode_from_string(string: String) -> DisplayServer.VSyncMode:
	match string:
		"enabled":
			return DisplayServer.VSYNC_ENABLED
		"adaptive":
			return DisplayServer.VSYNC_ADAPTIVE
		"mailbox":
			return DisplayServer.VSYNC_MAILBOX
		_:
			return DisplayServer.VSYNC_DISABLED


func _create_config_with_defaults() -> ConfigFile:
	var config_file: ConfigFile = ConfigFile.new()
	for section: String in _default_configuration.keys():
		var section_value: Dictionary = _default_configuration.get(section, {})
		for key: String in section_value.keys():
			config_file.set_value(section, key, section_value.get(key, null))

	return config_file


func _load_user_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return

	var user_config: ConfigFile = ConfigFile.new()
	var error: Error = user_config.load(CONFIG_PATH)
	if error != OK:
		push_error("Config could not be loaded with error code: %d" % [error,])
		return

	had_user_config = true
	for section: String in user_config.get_sections():
		for key: String in user_config.get_section_keys(section):
			if _file.has_section_key(section, key):
				set_value(
					section,
					key,
					user_config.get_value(section, key),
					false,
				)

	save()


func _setup_default_configuration() -> void:
	_default_configuration = {
		"gameplay": {
			"scroll_direction": "up",
			"centered_receptors": false,
			"manual_offset": 0.0,
			"scroll_speed_method": "chart",
			"custom_scroll_speed": 1.0,
			"binds": {
				"left": KEY_D,
				"down": KEY_F,
				"up": KEY_J,
				"right": KEY_K,
			},
		},
		"sound": {
			"buses": {
				"Master": 10.0,
				"Music": 100.0,
				"SFX": 100.0,
			},
		},
		"interface": {
			"underlay_alpha": 0.0,
			"rating_alpha": 100.0,
			"sustain_layer": "below",
			"song_label_show": true,
			"cpu_strums_press": true,
			"note_splash_alpha": 80.0,
			"countdown_on_resume": false,
			"scene_transitions": true,
		},
		"performance": {
			"intensive_visuals": true,
			"auto_pause": false,
			"fps_cap": 0.0,
			"dpi_awareness": true,
			"vsync_mode": "disabled",
			"debug_label": "default",
			"debug_label_visible": false,
		},
		"accessibility": {
			"flashing_lights": true,
			"locale": "en",
		},
	}

	# Non desktop platforms generally don't work so well
	# with vsync disabled, *and* usually have their own
	# built-in scaling methods.
	if not OS.has_feature("pc"):
		_default_configuration.performance.dpi_awareness = false
		_default_configuration.performance.vsync_mode = "enabled"
	else:
		var refresh_rate: float = DisplayServer.screen_get_refresh_rate()
		if refresh_rate > 0.0:
			_default_configuration.performance.fps_cap = refresh_rate * 2.0
