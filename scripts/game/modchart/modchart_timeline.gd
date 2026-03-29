#https://github.com/troll-slaiyers/FNF-Troll-Engine/blob/main/source/funkin/modchart/EventTimeline.hx
class_name ModchartTimeline extends Object

var modchart_manager: ModchartManager
var events: Array[ModchartEvent] = []
var modifier_events: Dictionary[String, Array] = {}

func _init(_modchart_manager: ModchartManager) -> void:
	modchart_manager = _modchart_manager

func _sort_events(array: Array) -> void:
	array.sort_custom(func(a: ModchartEvent, b: ModchartEvent) -> bool: return a.exec_step < b.exec_step)

func add_event(event: ModchartSetEvent) -> void:
	if !modifier_events.has(event.modifier):
		modifier_events.set(event.modifier, [])
	var schedule: Array = modifier_events.get(event.modifier)
	if !schedule.has(event):
		schedule.push_back(event)
	_sort_events(schedule)

func process_mods(step: float) -> void:
	for modifier: ModchartSetEvent in modifier_events.keys():
		var garbage: Array[ModchartSetEvent] = []
		for event: ModchartSetEvent in modifier_events.get(modifier):
			if event.finished:
				garbage.push_back(event)
				continue
			if event.ignore_exec:
				continue
			if step >= event.exec_step:
				event.run(step)
		for event in garbage:
			modifier_events.get(modifier).erase(event)
