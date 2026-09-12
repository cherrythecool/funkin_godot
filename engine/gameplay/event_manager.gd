class_name EventManager
extends Node


signal event_prepare(event: EventData)
signal event_hit(event: EventData)


var events: Array[EventData]
var events_index := 0


func _process(_delta: float) -> void:
	while (
		events_index < events.size() and
		Conductor.time >= events[events_index].time
	):
		event_hit.emit(events[events_index])
		events_index += 1
