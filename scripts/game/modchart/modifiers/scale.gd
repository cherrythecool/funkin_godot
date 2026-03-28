# https://github.com/nebulazorua/andromeda-engine-legacy/blob/master/source/modchart/modifiers/ScaleModifier.hx
class_name ScaleModifier extends ModchartModifier

func _init() -> void:
	var _submods: Array[String] = ["squish", "stretch", "mini_x", "mini_y"]
	for i: int in range(20):
		_submods.push_back('mini%s_x' % [i])
		_submods.push_back('mini%s_y' % [i])
		_submods.push_back('squish%s' % [i])
		_submods.push_back('stretch%s' % [i])
	super(_submods)

func get_note(note:Note, player:int) -> void:
	_scale(note, player, note.data.direction  % note.directions.size())
	
func get_receptor(receptor:Receptor, field:NoteField, player:int) -> void:
	_scale(receptor, player, field.receptors.find(receptor))

func _scale(object: Node2D, player: int, column: int) -> void:
	object.scale.x *= 1 - get_value(player)
	object.scale.y *= 1 - get_value(player)
	var miniX: float = submods.get("mini_x").get_value(player) + submods.get("mini%s_x" % [column]).get_value(player)
	var miniY: float = submods.get("mini_y").get_value(player) + submods.get("mini%s_y" % [column]).get_value(player)

	object.scale.x *= 1 - miniX
	object.scale.y *= 1 - miniY

	var stretch: float = submods.get("stretch").get_value(player) + submods.get('stretch%s' % [column]).get_value(player)
	var squish: float = submods.get("squish").get_value(player) + submods.get('squish%s' % [column]).get_value(player)

	var stretchX: float = lerpf(1,0.5,stretch)
	var stretchY: float = lerpf(1,2,stretch)

	var squishX: float =lerpf(1, 2, squish)
	var squishY: float =lerpf(1, 0.5, squish)
	
	object.scale.x *=(sin(rad_to_deg(object.rotation)*PI/180)*squishY)+(cos(rad_to_deg(object.rotation)*PI/180)*squishX);
	object.scale.x*=(sin(rad_to_deg(object.rotation)*PI/180)*stretchY)+(cos(rad_to_deg(object.rotation)*PI/180)*stretchX);

	object.scale.y*=(cos(rad_to_deg(object.rotation)*PI/180)*stretchY)+(sin(rad_to_deg(object.rotation)*PI/180)*stretchX);
	object.scale.y*=(cos(rad_to_deg(object.rotation)*PI/180)*squishY)+(sin(rad_to_deg(object.rotation)*PI/180)*squishX);
