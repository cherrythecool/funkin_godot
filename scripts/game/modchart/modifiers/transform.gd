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

func get_receptor(receptor:Receptor, field:NoteField, player:int) -> void:
	var receptor_id: int = field.receptors.find(receptor)
	
	receptor.position.x += submods.get("transformX").get_value(player) + submods.get("transform%sX" % [receptor_id]).get_value(player)
	receptor.position.y += submods.get("transformY").get_value(player) + submods.get("transform%sY" % [receptor_id]).get_value(player)
	
	receptor.position.x += (submods.get("moveX").get_value(player) + submods.get("move%sX" % [receptor_id]).get_value(player)) * 112
	receptor.position.y += (submods.get("moveY").get_value(player) + submods.get("move%sY" % [receptor_id]).get_value(player)) * 112

func get_note(note:Note, player:int) -> void:
	var note_id: int = note.data.direction % 4
	
	note.position.x += submods.get("transformX").get_value(player) + submods.get("transform%sX" % [note_id]).get_value(player)
	note.position.y += submods.get("transformY").get_value(player) + submods.get("transform%sY" % [note_id]).get_value(player)
	
	note.position.x += (submods.get("moveX").get_value(player) + submods.get("move%sX" % [note_id]).get_value(player)) * 112
	note.position.y += (submods.get("moveY").get_value(player) + submods.get("move%sY" % [note_id]).get_value(player)) * 112
