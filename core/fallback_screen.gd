extends Control


@onready var keybind_display: Alphabet = %keybind_display


func _ready() -> void:
	var controls: Dictionary = Settings.get_setting(&"core", "controls_keybinds")
	keybind_display.text = keybind_display.text.replace(
		"{KEYBIND}",
		GameUtils.keycode_to_character(controls["module_select"][0]),
	).replace(
		"{MODULE}",
		ModuleManager.current_module,
	)
