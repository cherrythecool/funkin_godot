extends Resource
class_name EventData


@export var name: StringName = &'Event'
@export var data: Array = []
@export var time: float = 0.0


func _to_string() -> String:
	return "EventData {name: %s, data: %s, time: %f}" % [name, data, time]
