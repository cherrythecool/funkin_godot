class_name TransformModifier extends ModchartModifier

func _init() -> void:
	var _submods: Array[String] = ["transform_x", "transform_y", "transform_z", "move_x", "move_y", "move_z"]
	for i: int in range(20): # theoretically supports up to 20 keys
		_submods.push_back('transform%s_x' % [i])
		_submods.push_back('transform%s_y' % [i])
		_submods.push_back('transform%s_z' % [i])
		
		_submods.push_back('move%s_x' % [i])
		_submods.push_back('move%s_y' % [i])
		_submods.push_back('move%s_z' % [i])
	super(_submods)
	
func get_object(object: Node, _field: NoteField, column:int, player: int) -> void:
	object.position.x += submods.get("transform_x").get_value(player) + submods.get("transform%s_x" % [column]).get_value(player)
	object.position.y += submods.get("transform_x").get_value(player) + submods.get("transform%s_y" % [column]).get_value(player)
	object.z_index += submods.get("transform_z").get_value(player) + submods.get("transform%s_z" % [column]).get_value(player)
	
	object.position.x += (submods.get("move_x").get_value(player) + submods.get("move%s_x" % [column]).get_value(player)) * 112
	object.position.y += (submods.get("move_y").get_value(player) + submods.get("move%s_y" % [column]).get_value(player)) * 112
