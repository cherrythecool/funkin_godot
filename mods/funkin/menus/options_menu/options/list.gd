extends Option


@export var file: StringName = &"core"
@export var key: StringName = &"note_scroll_method"
@export var list: Array[Variant] = ["chart"]

@export var display_overrides: Dictionary[Variant, String] = {}
@export var display_raw: bool = true

@export var value_label: Alphabet

var value: Variant:
	set(new_value):
		if new_value != SaveData.get_save_value(file, key):
			SaveData.set_save_value(file, key, new_value)

		value = new_value
		value_label.text = str(value) if display_raw else format_value()


func _ready() -> void:
	value = SaveData.get_save_value(file, key)


func _select() -> void:
	var index: int = maxi(list.find(value), 0)
	value = list[wrapi(index + 1, 0, list.size())]
	MenuAudio.confirm.play()


func format_value() -> String:
	if display_overrides.has(value):
		return display_overrides[value]

	if value is String:
		return value.replace("_", " ")
	elif value is float:
		return str(int(value))
	else:
		return value
