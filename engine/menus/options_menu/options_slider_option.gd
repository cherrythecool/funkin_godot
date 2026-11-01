extends HBoxContainer


@export var option_name: String = "note_scroll_value"
@export var label_suffix: String = " speed"
@export var label_decimals: int = 1

@onready var option_slider: HSlider = $OptionSlider
@onready var option_value_label: Label = $OptionValueLabel


func _ready() -> void:
	option_slider.value_changed.connect(_on_value_changed)
	option_slider.value = SaveData.get_save_value(&"core", option_name, 0.0)


func _on_value_changed(value: float) -> void:
	if option_slider.rounded:
		SaveData.set_save_value(&"core", option_name, roundi(value))
		option_value_label.text = "%d%s" % [roundi(value), label_suffix]
	else:
		SaveData.set_save_value(&"core", option_name, value)
		option_value_label.text = "%.*f%s" % [label_decimals, value, label_suffix]
