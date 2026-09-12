class_name DynamicEvent
extends EventData



func _init(
	name_: StringName,
	time_: float,
	data_: Variant,
) -> void:
	name = name_
	time = time_
	data[&"values"] = data_
