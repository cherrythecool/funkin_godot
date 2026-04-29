#https://github.com/troll-slaiyers/FNF-Troll-Engine/blob/main/source/funkin/modchart/EventTimeline.hx
class_name ModchartTimeline extends Object

var modchart_manager: ModchartManager
var events: Array[ModchartEvent] = []

func _init(_modchart_manager: ModchartManager) -> void:
	modchart_manager = _modchart_manager


func add_event(event: ModchartEvent) -> void:
	if !events.has(event):
		events.push_back(event)
	events.sort_custom(func(a: ModchartEvent, b: ModchartEvent) -> bool: return a.exec_step < b.exec_step)

func process_mods(step: float) -> void:
	var garbage: Array[ModchartSetEvent] = []
	for event: ModchartEvent in events:
		if event.finished:
			garbage.push_back(event)
			continue
		if event.ignore_exec:
			continue
		if step >= event.exec_step:
			event.run(step)
	for event: ModchartEvent in garbage:
		events.erase(event)