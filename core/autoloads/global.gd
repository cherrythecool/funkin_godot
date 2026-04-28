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

	Config.value_changed.connect(_on_config_value_changed)
	Config.loaded.connect(_on_config_loaded)

	is_mobile = DisplayServer.is_touchscreen_available() and OS.has_feature("mobile")


func _on_focus_enter() -> void:
	if not Config.get_value("performance", "auto_pause"):
		return

	get_tree().paused = false


func _on_focus_exit() -> void:
	if not Config.get_value("performance", "auto_pause"):
		return

	var tree: SceneTree = get_tree()
	was_paused = tree.paused
	tree.paused = true


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action(&"menu_fullscreen"):
		get_viewport().set_input_as_handled()
		fullscreened = not fullscreened
		return
	if event.is_action(&"menu_reload"):
		SceneManager.reload_current_scene()
		return


func _on_config_value_changed(section: String, key: String, value: Variant) -> void:
	if value == null or section != "performance":
		return

	match key:
		"fps_cap":
			Engine.max_fps = value
		"vsync_mode":
			DisplayServer.window_set_vsync_mode(
				Config.get_vsync_mode_from_string(value)
			)


func _on_config_loaded() -> void:
	_on_config_value_changed(
		"performance",
		"fps_cap",
		Config.get_value("performance", "fps_cap"),
	)

	_on_config_value_changed(
		"performance",
		"vsync_mode",
		Config.get_value("performance", "vsync_mode"),
	)

	use_high_dpi = (
		not Engine.is_embedded_in_editor() and
		OS.has_feature("pc") and
		ProjectSettings.get_setting("display/window/dpi/allow_hidpi", true) and
		Config.get_value("performance", "dpi_awareness")
	)

	if use_high_dpi:
		var dpi_scale: float = DisplayServer.screen_get_scale()
		if dpi_scale != 1.0:
			get_window().size *= dpi_scale
			get_window().move_to_center()
