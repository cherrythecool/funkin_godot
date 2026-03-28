class_name ModchartModifier extends Object

var values:Array[float] = [0, 0]
var submods:Dictionary[String, ModchartModifier] = {}

func _init(_submods:Array[String] = []) -> void:
	for mod:String in _submods:
		submods.set(mod, ModchartModifier.new())

func get_value(player:int) -> float:
	if values.size() <= player:
		values.resize(player)
	if values[player] == null:
		values[player] = 0
	return values[player]

func set_value(value:float, player:int) -> void:
	if player < 0:
		values = [value, value]
	else:
		values[player] = value

@warning_ignore("unused_parameter")
func get_note(note: Note, player: int) -> void: pass
@warning_ignore("unused_parameter")
func get_receptor(receptor: Receptor, field: NoteField, player: int) -> void:pass
