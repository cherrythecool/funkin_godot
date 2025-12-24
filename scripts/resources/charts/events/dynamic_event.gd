extends EventData
class_name DynamicEvent



func _init(name_str: StringName = &"", time_val: float = 0.0, values: Variant = null) -> void:
	name = name_str
	time = time_val
	if values != null:
		data.push_back(values)
