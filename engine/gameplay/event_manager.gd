class_name EventManager
extends Node


signal event_prepare(event: EventData)
signal event_hit(event: EventData)


@export var use_custom_events_path := false
@export_dir var custom_events_path := ""


var loaded_events: Array[Node]
var events: Array[EventData]
var events_index := 0


func _ready() -> void:
	if Game.instance:
		Game.instance.chart_loaded.connect(_on_chart_loaded)
		Game.instance.ready_post.connect(prepare_events)


func _process(_delta: float) -> void:
	if not Conductor.active:
		return

	while events_index < events.size() and Conductor.time >= events[events_index].time:
		hit_current_event()


func hit_current_event() -> void:
	event_hit.emit(events[events_index])
	events_index += 1


func prepare_events() -> void:
	for event: EventData in events:
		event_prepare.emit(event)

	# trigger events that happen as the game starts, well...
	# as it starts!
	while events_index < events.size() and events[events_index].time <= 0.001:
		if not events[events_index].trigger_before_countdown:
			break

		hit_current_event()


func _on_chart_loaded(chart: Chart) -> void:
	events = chart.events
	events_index = 0
	_load_events()


func _load_events() -> void:
	GameUtils.free_from_array(loaded_events)
	loaded_events.clear()

	var already_loaded_names: Array[StringName] = []
	var base_path := "res://mods/%s/events" %  ModSwitcher.current_module
	if use_custom_events_path:
		base_path = custom_events_path

		if base_path.ends_with("/"):
			base_path = base_path.left(-1)

	for event: EventData in events:
		var event_name: StringName = event.name
		if already_loaded_names.has(event_name):
			continue

		already_loaded_names.push_back(event_name)

		var path: String = "%s/%s.tscn" % [base_path, event_name]
		if not ResourceLoader.exists(path, "PackedScene"):
			path = "%s/%s.tscn" % [base_path, event_name.to_snake_case()]

		if not ResourceLoader.exists(path, "PackedScene"):
			push_warning("Missing event with name '%s', tried snake case as well as full event name" % event_name)
			continue

		var scene: PackedScene = load(path)
		var loaded_event: Node = scene.instantiate()
		loaded_events.push_back(loaded_event)
		add_child(loaded_event)
