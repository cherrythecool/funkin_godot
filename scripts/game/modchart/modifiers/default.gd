class_name DefaultModifier extends ModchartModifier

func get_object(object: Node, field: NoteField, _column:int, _player: int) -> void:
	if object is Note:
		object.position.y -= (Conductor.instance.time - object.data.time) * 1000.0 * 0.45 * field.get_scroll_speed()
