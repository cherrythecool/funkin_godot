# https://github.com/nebulazorua/andromeda-engine-legacy/blob/master/source/modchart/modifiers/BeatModifier.hx
class_name InvertModifier extends ModchartModifier

func _init() -> void:
	super([])

func get_receptor(receptor: Receptor, field: NoteField, player: int) -> void:
	var thing: int = 1 if field.receptors.find(receptor) % 2 == 0 else -1
	var distance: float = 112 * thing
	receptor.position.x += distance * get_value(player)

func get_note(note: Note, player: int) -> void:
	var thing: int = 1 if (note.data.direction % note.directions.size()) % 2 == 0 else -1
	var distance: float = 112 * thing
	note.position.x += distance * get_value(player)
