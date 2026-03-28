# https://github.com/nebulazorua/andromeda-engine-legacy/blob/master/source/modchart/modifiers/ConfusionModifier.hx
class_name ConfusionModifier extends ModchartModifier

func _init() -> void:
	var _submods: Array[String] = [
		"note_angle",
		"receptor_angle"
	]
	for i: int in range(20):
		_submods.push_back('note%s_angle' % [i])
		_submods.push_back('receptor%s_angle' % [i])
		_submods.push_back('confusion%s' % [i])
	super(_submods)

func get_note(note:Note, player:int) -> void:
	var note_id: int = note.data.direction  % note.directions.size()
	note.rotation = deg_to_rad(get_value(player) + submods.get('confusion%s' % [note_id]).get_value(player) + submods.get('note%s_angle' % [note_id]).get_value(player))

func get_receptor(receptor:Receptor, field:NoteField, player:int) -> void:
	var receptor_id: int = field.receptors.find(receptor)
	receptor.rotation = deg_to_rad(get_value(player) + submods.get('confusion%s' % [receptor_id]).get_value(player) + submods.get('receptor%s_angle' % [receptor_id]).get_value(player))
