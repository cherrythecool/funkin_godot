# https://github.com/troll-slaiyers/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/OpponentModifier.hx
class_name OpponentModifier extends ModchartModifier

func _init() -> void:
	super([])

func get_object(object: Node, _field: NoteField, _column:int, player: int) -> void:
	if object is Receptor:
		var dist: float = Global.game_size.x / Game.instance.modchart_manager.note_fields.size()
		object.position.x += dist * sign((player + 1) * 2 - 3) * get_value(player)
