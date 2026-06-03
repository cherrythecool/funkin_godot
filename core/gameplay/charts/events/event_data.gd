class_name EventData
extends RefCounted


@export var name: StringName = &"Event"
@export var data: Dictionary[StringName, Variant] = {}
@export var time: float = 0.0
@export var trigger_before_countdown: bool = false


func _to_string() -> String:
	return "EventData {name: %s, data: %s, time: %s, before_countdown: %s}" % [
		name,
		data,
		time,
		trigger_before_countdown,
	]
