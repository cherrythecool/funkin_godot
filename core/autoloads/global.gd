extends Node


var fullscreened: bool = false:
	set(value):
		if main_window.unresizable:
			return
		if not Engine.is_embedded_in_editor():
			main_window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if value else Window.MODE_WINDOWED
	get:
		if Engine.is_embedded_in_editor():
			return false
		return main_window.mode != Window.MODE_WINDOWED

var game_size: Vector2:
	get:
		return get_viewport().get_visible_rect().size

var version: String = "Unknown"
var was_paused: bool = false
var main_window: Window = null

var is_mobile: bool = false
var use_high_dpi: bool = false


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	# clear color without changing in editor
	RenderingServer.set_default_clear_color(Color.BLACK)

	main_window = get_window()
	main_window.focus_entered.connect(_on_focus_enter)
	main_window.focus_exited.connect(_on_focus_exit)

	version = ProjectSettings.get_setting("application/config/version", "0.0.0-unknown")

	Settings.setting_changed.connect(_on_setting_changed)
	Settings.settings_loaded.connect(_on_settings_loaded)

	is_mobile = DisplayServer.is_touchscreen_available() and OS.has_feature("mobile")


func _on_focus_enter() -> void:
	if not Settings.get_setting(&"core", "pause_when_unfocused"):
		return

	get_tree().paused = was_paused


func _on_focus_exit() -> void:
	if not Settings.get_setting(&"core", "pause_when_unfocused"):
		return

	was_paused = get_tree().paused
	get_tree().paused = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action(&"menu_fullscreen"):
		get_viewport().set_input_as_handled()
		fullscreened = not fullscreened
		return
	if event.is_action(&"menu_reload"):
		SceneManager.reload_current_scene()
		return


func get_supported_vsync() -> DisplayServer.VSyncMode:
	if RenderingServer.get_rendering_device() == null:
		return DisplayServer.VSYNC_ENABLED

	# Automatically will fallback if not supported
	# (would default to MAILBOX but it's not very well supported atm)
	return DisplayServer.VSYNC_ADAPTIVE


func _on_setting_changed(file: StringName, key: Variant) -> void:
	var value: Variant = Settings.get_setting(file, key)
	if file != &"core" or value == null:
		return

	match key:
		"max_fps":
			Engine.max_fps = value
		"vsync_enabled":
			if value:
				DisplayServer.window_set_vsync_mode(get_supported_vsync())
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_settings_loaded(file: StringName) -> void:
	if file != &"core":
		return

	use_high_dpi = (
		not Engine.is_embedded_in_editor() and
		OS.has_feature("pc") and
		ProjectSettings.get_setting("display/window/dpi/allow_hidpi", true) and
		Settings.get_setting(&"core", "scale_with_dpi", true)
	)

	if use_high_dpi:
		var dpi_scale: float = DisplayServer.screen_get_scale()
		if dpi_scale != 1.0:
			get_window().size *= dpi_scale
			get_window().move_to_center()
