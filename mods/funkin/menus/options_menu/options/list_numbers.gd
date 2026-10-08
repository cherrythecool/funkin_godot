extends Option


@export var section: StringName = &'performance'
@export var key: StringName = &'fps_cap'
@export var list: Array[float] = [0.0]
@export var display_float: bool = true

@onready var value_label: Alphabet = $value

var value: float:
	set(new_value):
		if new_value != SaveData.get_save_value(&"core", key):
			SaveData.set_save_value(&"core", key, new_value)

		value = new_value
		value_label.text = str(value) if display_float else str(int(value))


func _ready() -> void:
	value = SaveData.get_save_value(&"core", key)


func _select() -> void:
	var index: int = list.find(value)
	if index < 0:
		index = 0

	value = list[wrapi(index + 1, 0, list.size())]
	MenuAudio.confirm.play()
