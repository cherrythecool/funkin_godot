# https://github.com/nebulazorua/andromeda-engine-legacy/blob/master/source/modchart/modifiers/BeatModifier.hx
class_name InvertModifier extends ModchartModifier

func _init() -> void:
	super([])
	
func get_object(object: Node, _field: NoteField, column:int, player: int) -> void:
	var thing: int = 1 if column % 2 == 0 else -1
	var distance: float = 112 * thing
	object.position.x += distance * get_value(player)
