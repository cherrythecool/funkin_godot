extends CheckBox


@export var option_name: String = "downscroll"


func _ready() -> void:
	button_pressed = SaveData.get_save_value(&"core", option_name, false)


func _toggled(toggled_on: bool) -> void:
	SaveData.set_save_value(&"core", option_name, toggled_on)
