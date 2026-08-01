extends ModchartModifier

var beat_factors:Dictionary = {}

func get_id() -> String:
	return "beat"

func get_sub_modifier_ids() -> Array[String]:
	return [
		"beat_offset",
		"beat_period",
		"beat_mult",
		"beat_y",
		"beat_y_offset",
		"beat_y_period",
		"beat_y_mult",
		"beat_z",
		"beat_z_offset",
		"beat_z_period",
		"beat_z_mult"
	]

func update_modifier(delta:float) -> void:
	var beat = manager.adapter.get_song_beat()
	for player in range(manager.players.size()):
		_update_beat(0, beat, player, get_value(player, "beat_offset"), get_value(player, "beat_mult"))
		_update_beat(1, beat, player, get_value(player, "beat_y_offset"), get_value(player, "beat_y_mult"))
		_update_beat(2, beat, player, get_value(player, "beat_z_offset"), get_value(player, "beat_z_mult"))

func _update_beat(axis:int, beat:float, player:int, offset:float, mult:float) -> void:
	if !beat_factors.has(player):
		beat_factors[player] = Vector3.ZERO

	var accel_time = 0.2
	var total_time = 0.5
	beat = (beat + accel_time + offset) * (mult + 1.0)
	var even_beat = int(beat) % 2 != 0

	if beat < 0.0:
		return

	beat -= floor(beat)
	beat += 1.0
	beat -= floor(beat)

	if beat >= total_time:
		return

	var amount = 0.0
	if beat < accel_time:
		amount = remap(beat, 0.0, accel_time, 0.0, 1.0)
		amount *= amount
	else:
		amount = remap(beat, accel_time, total_time, 1.0, 0.0)
		amount = 1.0 - (1.0 - amount) * (1.0 - amount)

	if even_beat:
		amount *= -1.0

	var current_factors = beat_factors[player]
	if axis == 0:
		current_factors.x = 40.0 * amount
	elif axis == 1:
		current_factors.y = 40.0 * amount
	elif axis == 2:
		current_factors.z = 40.0 * amount
	beat_factors[player] = current_factors

func _adjust(val:float, player:int) -> float:
	if get_value(player, "legacy_z_axis") > 0.0:
		return val / 1280.0
	return val

func get_position(position:Vector3, origin:Variant, type:ModchartManager.ObjectType, visual_time:float, direction:int, player:int) -> Vector3:
	if not beat_factors.has(player):
		var beat = manager.adapter.get_song_beat()
		_update_beat(0, beat, player, get_value(player, "beat_offset"), get_value(player, "beat_mult"))
		_update_beat(1, beat, player, get_value(player, "beat_y_offset"), get_value(player, "beat_y_mult"))
		_update_beat(2, beat, player, get_value(player, "beat_z_offset"), get_value(player, "beat_z_mult"))

	var factors = beat_factors[player]
	var beat_period = get_value(player, "beat_period")
	var beat_y_period = get_value(player, "beat_y_period")
	var beat_z_period = get_value(player, "beat_z_period")

	position.x += get_value(player) * (factors.x * sin((position.y / ((beat_period * 30.0) + 30.0)) + PI * 0.5))
	position.y += get_value(player, "beat_y") * (factors.y * sin((position.y / ((beat_y_period * 30.0) + 30.0)) + PI * 0.5))
	position.z += _adjust(get_value(player, "beat_z") * (factors.z * sin((position.y / ((beat_z_period * 30.0) + 30.0)) + PI * 0.5)), player)
	return position
