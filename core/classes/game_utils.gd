class_name GameUtils
extends Object


static func free_children_from(node: Node, immediate: bool = false) -> void:
	while node.get_child_count() > 0:
		var child: Node = node.get_child(0)
		node.remove_child(child)

		if immediate:
			child.free()
		else:
			child.queue_free()


static func free_from_array(nodes: Array[Node], immediate: bool = false) -> void:
	for child: Node in nodes:
		if not is_instance_valid(child):
			continue

		if immediate:
			child.free()
		else:
			child.queue_free()


# Shit from V-Slice mostly
static func get_ease_from_fnfc(string: String) -> Tween.EaseType:
	if string.ends_with("Out"):
		return Tween.EASE_OUT
	if string.ends_with("InOut"):
		return Tween.EASE_IN_OUT
	if string.ends_with("OutIn"):
		return Tween.EASE_OUT_IN

	return Tween.EASE_IN


static func get_trans_from_fnfc(string: String) -> Tween.TransitionType:
	const KNOWN_MAP: Dictionary[StringName, Tween.TransitionType] = {
		&"sine": Tween.TRANS_SINE,
		&"circ": Tween.TRANS_CIRC,
		&"cube": Tween.TRANS_CUBIC,
		&"quad": Tween.TRANS_QUAD,
		&"quart": Tween.TRANS_QUART,
		&"quint": Tween.TRANS_QUINT,
		&"expo": Tween.TRANS_EXPO,
		&"elastic": Tween.TRANS_ELASTIC,

		# NOTE: This *may* be supported by HaxeFlixel, but is not
		# natively by Godot. It could technically be added with
		# custom tween functions, but that is not currently top
		# priority, so this is the solution for now.
		&"smoothStep": Tween.TRANS_CUBIC
	}

	for key: StringName in KNOWN_MAP.keys():
		if string.begins_with(key):
			return KNOWN_MAP[key]

	return Tween.TRANS_LINEAR


static func get_accurate_time(player: AudioStreamPlayer) -> float:
	return (player.get_playback_position() + (
		AudioServer.get_time_since_last_mix() * player.pitch_scale))


static func lerp_weight(delta: float, constant: float) -> float:
	return minf(1.0 - exp(-constant * delta), 1.0)
