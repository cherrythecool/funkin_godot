extends ModchartModifier

func get_id() -> String:
	return "opponent_swap"

func _sign(x: int) -> int:
	if x == 0:
		return 0
	return -1 if x <= -1 else 1

func get_position(position: Vector3, origin: Variant, type: ModchartManager.ObjectType, visual_time:float, direction: int, player: int) -> Vector3:
	var screen_width = 1280.0
	var dist_x = screen_width / float(manager.players.size())
	position.x += dist_x * _sign((player + 1) * 2 - 3) * get_value(player)
	return position
