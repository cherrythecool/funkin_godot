extends NumberOption


@export var bus: StringName = &'Master'


func _ready() -> void:
	var buses: Dictionary = SaveData.get_save_value(&"core", "volume")
	value = buses[bus] * 100.0


func set_value(value_: Variant) -> void:
	value_ /= 100.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(value_))

	var buses: Dictionary = SaveData.get_save_value(&"core", "volume")
	buses[bus] = value_
	SaveData.set_save_value(&"core", "volume", buses)
