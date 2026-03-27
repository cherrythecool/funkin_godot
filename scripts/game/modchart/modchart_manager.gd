class_name ModchartManager extends Node

var modifiers: Dictionary = {}

var note_fields: Array[NoteField] = []
var initial_receptor_positions: Dictionary[Receptor, Vector2] = {}

func _init() -> void: 
	_register_default_modifiers()
	Game.instance.conductor.beat_hit.connect(_on_beat_hit)
	
func _register_default_modifiers() -> void: 
	modifiers.set("__fallback_modifier", ModchartModifier.new())
	
	modifiers.set("drunk", DrunkModifier.new())

func _process(_delta: float) -> void:
	for i:int in note_fields.size():
		var field: NoteField = note_fields[i]
		for receptor: Receptor in field.receptors:
			receptor.global_position = initial_receptor_positions.get(receptor)
			for mod: ModchartModifier in modifiers.values(): mod.receptor(receptor, field, i)
		
func add_note_field(field: NoteField) -> void:
	note_fields.push_back(field)
	for receptor: Receptor in field.receptors:
		initial_receptor_positions.set(receptor, receptor.global_position)
	
	field.note_update.connect(func(note: Note) -> void:
		for mod: ModchartModifier in modifiers.values():
			note.global_position.x = initial_receptor_positions.get(field.receptors[note.data.direction % 4]).x
			mod.note(note, note_fields.size() - 1)
	)

func get_modifier(mod: String) -> ModchartModifier:
	if !modifiers.has(mod): 
		printerr('Modifier %1 not found.' % [mod])
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
		printerr('Sub modifier %1 of %2 not found.' % [submod, mod])
	return modifiers.get("__fallback_modifier")

func set_submod_value(mod: String, submod: String, value: float, player: int = -1) -> void:
	get_submod(mod, submod).set_value(value, player)
	
func set_submod_percent(mod: String, submod: String, percent: float, player: int = -1) -> void:
	set_submod_value(mod, submod, percent/100, player)

func get_submod_value(mod: String, submod: String, player: int = 0) -> float:
	return get_submod(mod, submod).get_value(player)

func get_submod_percent(mod: String, submod: String, player: int = 0) -> float:
	return get_submod_value(mod, submod, player) * 100

# Queue Events
var queues:Array = []

func _on_beat_hit(beat:int):
	pass
