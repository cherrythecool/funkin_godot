extends HBoxContainer


@export var bus_name: String = "Master"
@export var label_suffix: String = "%"

@onready var option_slider: HSlider = $OptionSlider
@onready var option_value_label: Label = $OptionValueLabel


func _ready() -> void:
	option_slider.value_changed.connect(_on_value_changed)

	var volumes: Dictionary = SaveData.get_save_value(&"core", "volume", {})
	option_slider.value = volumes[bus_name] * 100.0


func _on_value_changed(value: float) -> void:
	var volumes: Dictionary = SaveData.get_save_value(&"core", "volume", {})
	volumes[bus_name] = value / 100.0
	SaveData.set_save_value(&"core", "volume", volumes)

	option_value_label.text = "%d%s" % [roundi(value), label_suffix]
