class_name AccelModifier extends ModchartModifier

func _init() -> void:
	super([
		"boost",
		"brake",
		"wave"
	])

func get_object(object: Node, _field: NoteField, column: int, player: int) -> void:
	if object is not Note:
		return
	
	var boost_perc: float = submods.get("boost").get_value(player) # Haxe版のgetValue(player)に対応 [cite: 22]
	var brake_perc: float = submods.get("brake").get_value(player)
	var wave_perc: float = submods.get("wave").get_value(player)
	
	var effect_height: float = 500.0
	var time: float = Conductor.instance.time

	var vis_diff: float = 0.0
	if object is Note:
		vis_diff = -((time - object.data.time) * 450.0 * Game.instance.scroll_speed)

	var y_adjust: float = 0.0
	
	# TODO: reimplement this
	#var reverse_modifier = modchart_manager.modifiers.get("reverse")
	#var reverse_percent: float = reverse_modifier.get_reverse_value(column, player) 
	#var mult: float = remap(reverse_percent, 0.0, 1.0, 1.0, -1.0) 
	var mult: float = 1

	if brake_perc != 0:
		var scale: float = remap(vis_diff, 0.0, effect_height, 0.0, 1.0) 
		scale = clamp(scale, 0.0, 1.0)
		var off: float = vis_diff * scale
		y_adjust += clamp(brake_perc * (off - vis_diff), -400.0, 400.0)

	if boost_perc != 0:
		var divisor: float = (vis_diff + effect_height / 1.2) / effect_height
		if divisor != 0:
			var off: float = vis_diff * 1.5 / divisor
			y_adjust += clamp(boost_perc * (off - vis_diff), -400.0, 400.0)

	if wave_perc != 0:
		y_adjust += wave_perc * 20.0 * sin(vis_diff / 38.0)

	object.position.y += y_adjust * mult
