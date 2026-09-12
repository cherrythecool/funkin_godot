extends Control


@export var keybind_display: Alphabet


func _ready() -> void:
	var controls: Dictionary = Settings.get_setting(&"core", "controls_keybinds")
	keybind_display.text = keybind_display.text.replace(
		"{KEYBIND}",
		GameUtils.keycode_to_character(controls["module_select"][0]),
	).replace(
		"{MODULE}",
		ModSwitcher.current_module,
	)
