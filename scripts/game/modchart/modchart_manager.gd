class_name ModchartManager extends Node

# TODO: Implement z-pos modifiers

var modifiers: Dictionary = {}

var note_fields: Array[NoteField] = []
var initial_receptor_data: Dictionary[Receptor, ModchartObjectData] = {}

func _init() -> void: 
	_register_default_modifiers()
	Game.instance.conductor.step_hit.connect(_on_step_hit)
	
func _register_default_modifiers() -> void: 
	modifiers.set("__fallback_modifier", ModchartModifier.new())
	
	modifiers.set("drunk", DrunkModifier.new())
	modifiers.set("confusion", ConfusionModifier.new())
	modifiers.set("scale", ScaleModifier.new())
	modifiers.set("transform", TransformModifier.new())
	modifiers.set("opponent_swap", OpponentModifier.new())
	modifiers.set("beat", BeatModifier.new())
	modifiers.set("invert", InvertModifier.new())

func _process(delta: float) -> void:
	for i:int in note_fields.size():
		var field: NoteField = note_fields[i]
		for receptor: Receptor in field.receptors:
			receptor.global_position = initial_receptor_data.get(receptor).position
			receptor.scale = initial_receptor_data.get(receptor).scale
			for mod: ModchartModifier in modifiers.values(): mod.get_receptor(receptor, field, i)
		
func add_note_field(field: NoteField) -> void:
	note_fields.push_back(field)
	for receptor: Receptor in field.receptors:
		initial_receptor_data.set(receptor, ModchartObjectData.new(receptor.global_position, receptor.scale))
	
	field.note_update.connect(func(note: Note) -> void:
		note.global_position.x = initial_receptor_data.get(field.receptors[note.data.direction % 4]).position.x
		note.scale = initial_receptor_data.get(field.receptors[note.data.direction % 4]).scale * 0.7
		for mod: ModchartModifier in modifiers.values():
			mod.get_note(note, note_fields.size() - 1)
	)

func get_modifier(mod: String) -> ModchartModifier:
	if !modifiers.has(mod): 
		printerr('Modifier %s not found.' % [mod])
		return modifiers.get("__fallback_modifier")
	return modifiers.get(mod)

func set_value(mod: String, value: float, player: int = -1) -> void:
	get_modifier(mod).set_value(value, player)
	
func set_percent(mod: String, percent: float, player: int = -1) -> void:
	set_value(mod, percent/100, player)

func get_value(mod: String, player: int = 0) -> float: 
	return get_modifier(mod).get_value(player)

func get_percent(mod: String, player: int = 0) -> float: 
	return get_value(mod, player) * 100

# Sub Modifiers
func get_submod(mod: String, submod: String) -> ModchartModifier:
	if get_modifier(mod) != null and get_modifier(mod).submods.has(submod):
		return get_modifier(mod).submods.get(submod)
	else: 
		printerr('Sub modifier %s of %s not found.' % [submod, mod])
	return modifiers.get("__fallback_modifier")

func set_submod_value(mod: String, submod: String, value: float, player: int = -1) -> void:
	get_submod(mod, submod).set_value(value, player)
	
func set_submod_percent(mod: String, submod: String, percent: float, player: int = -1) -> void:
	set_submod_value(mod, submod, percent/100, player)

func get_submod_value(mod: String, submod: String, player: int = 0) -> float:
	return get_submod(mod, submod).get_value(player)

func get_submod_percent(mod: String, submod: String, player: int = 0) -> float:
	return get_submod_value(mod, submod, player) * 100

# Queue/Events
var queues: Array[ModchartEvent] = []

func queue_set_value(step: int, mod: String, value: float, player: int = -1) -> void:
	var event: ModchartEvent = ModchartEvent.new(self)
	event.start_step = step
	event.modifier = mod
	event.value = value
	event.player = player
	queues.push_back(event)
	add_child(event)
	_sort_queues()

func queue_set_percent(step: int, mod: String, percent: float, player: int = -1) -> void:
	queue_set_value(step, mod, percent/100, player)
	
func queue_ease_value(start_step: int, end_step: int, mod: String, value: float, target_trans:Tween.TransitionType, target_ease:Tween.EaseType, player: int = -1, start_value: Variant = null) -> void:
	var event: ModchartEvent = ModchartEaseEvent.new(self)
	event.start_step = start_step
	event.end_step = end_step
	event.modifier = mod
	event.value = value
	event.target_trans = target_trans
	event.target_ease = target_ease
	event.player = player
	if start_value != null: event.start_value = start_value
	queues.push_back(event)
	add_child(event)
	_sort_queues()

func queue_ease_percent(start_step: int, end_step: int, mod: String, percent: float, target_trans:Tween.TransitionType, target_ease:Tween.EaseType, player: int = -1, start_percent: Variant = null) -> void:
	var start_value: Variant = null
	if start_percent != null: start_value = start_percent / 100
	queue_ease_value(start_step, end_step, mod, percent/100, target_trans, target_ease, player, start_value)

func queue_set_submod_value(step: int, mod: String, submod: String, value: float, player: int = -1) -> void:
	var event: ModchartEvent = ModchartEvent.new(self)
	event.start_step = step
	event.modifier = mod
	event.sub_modifier = submod
	event.value = value
	event.player = player
	queues.push_back(event)
	add_child(event)
	_sort_queues()

func queue_set_submod_percent(step: int, mod: String, submod: String, percent: float, player: int = -1) -> void:
	queue_set_submod_value(step, mod, submod, percent/100, player)
	
func queue_submod_ease_value(start_step: int, end_step: int, mod: String, submod: String, value: float, target_trans:Tween.TransitionType, target_ease:Tween.EaseType, player: int = -1, start_value: Variant = null) -> void:
	var event: ModchartEvent = ModchartEaseEvent.new(self)
	event.start_step = start_step
	event.end_step = end_step
	event.modifier = mod
	event.sub_modifier = submod
	event.value = value
	event.target_trans = target_trans
	event.target_ease = target_ease
	event.player = player
	if start_value != null: event.start_value = start_value
	queues.push_back(event)
	add_child(event)
	_sort_queues()

func queue_submod_ease_percent(start_step: int, end_step: int, mod: String, submod: String, percent: float, target_trans:Tween.TransitionType, target_ease:Tween.EaseType, player: int = -1, start_percent: Variant = null) -> void:
	var start_value: Variant = null
	if start_percent != null: start_value = start_percent / 100
	queue_submod_ease_value(start_step, end_step, mod, submod, percent/100, target_trans, target_ease, player, start_value)


func _sort_queues() -> void:
	queues.sort_custom(func(a: ModchartEvent, b: ModchartEvent) -> bool:
		return a.start_step < b.start_step)

func _on_step_hit(step:int) -> void:
	if !queues.is_empty():
		for event in queues:
			if step >= event.start_step:
				event.run()
				queues.erase(event)
				event.kill()
