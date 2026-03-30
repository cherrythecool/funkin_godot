class_name TransformModifier extends ModchartModifier

func _init() -> void:
	var _submods: Array[String] = ["transformX", "transformY", "transformZ", "moveX", "moveY", "moveZ"]
	for i: int in range(20): # theoretically supports up to 20 keys
		_submods.push_back('transform%sX' % [i])
		_submods.push_back('transform%sY' % [i])
		_submods.push_back('transform%sZ' % [i])
		
		_submods.push_back('move%sX' % [i])
		_submods.push_back('move%sY' % [i])
		_submods.push_back('move%sZ' % [i])
	super(_submods)
	
func get_object(object: Node, _field: NoteField, column:int, player: int) -> void:
	object.position.x += submods.get("transformX").get_value(player) + submods.get("transform%sX" % [column]).get_value(player)
	object.position.y += submods.get("transformY").get_value(player) + submods.get("transform%sY" % [column]).get_value(player)
	
	object.position.x += (submods.get("moveX").get_value(player) + submods.get("move%sX" % [column]).get_value(player)) * 112
	object.position.y += (submods.get("moveY").get_value(player) + submods.get("move%sY" % [column]).get_value(player)) * 112
