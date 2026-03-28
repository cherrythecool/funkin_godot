# https://github.com/troll-slaiyers/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/OpponentModifier.hx
class_name OpponentModifier extends ModchartModifier

func _init() -> void:
	super([])

func get_receptor(receptor:Receptor, field:NoteField, player:int) -> void:
	var dist = Global.game_size.x / values.size()
	receptor.position.x += dist * sign((player + 1) * 2 - 3) * get_value(player)

func get_note(note:Note, player:int) -> void:
	var dist = Global.game_size.x / values.size()
	note.position.x += dist * sign((player + 1) * 2 - 3) * get_value(player)
