extends ModchartModifier

func get_id() -> String:
	return "boost"

func get_sub_modifier_ids() -> Array[String]:
	return ["brake", "wave", "wave_period"]

func get_position(position:Vector3, origin:Variant, type:ModchartManager.ObjectType, visual_time:float, direction:int, player:int) -> Vector3:
	if get_value(player, "move_past_receptors") == 0.0 and position.y <= 0.0:
		return position

	var wave = get_value(player, "wave")
	var brake = get_value(player, "brake")
	var boost = get_value(player)
	var effect_height = 720.0
	var y_adjust = 0.0
	
	var reverse_percent = get_value(player, "reverse")
	var mult = remap(reverse_percent, 0.0, 1.0, 1.0, -1.0)

	if brake != 0.0:
		var scale = remap(position.y, 0.0, effect_height, 0.0, 1.0)
		var off = position.y * scale
		y_adjust += clamp(brake * (off - position.y), -600.0, 600.0)

	if boost != 0.0:
		var off = position.y * 1.5 / ((position.y + effect_height / 1.2) / effect_height)
		y_adjust += clamp(boost * (off - position.y), -600.0, 600.0)

	var wave_period = get_value(player, "wave_period")
	if wave_period != -1.0 and wave != 0.0:
		y_adjust += wave * 40.0 * sin(position.y / ((114.0 * wave_period) + 114.0))

	position.y += y_adjust * mult
	return position
