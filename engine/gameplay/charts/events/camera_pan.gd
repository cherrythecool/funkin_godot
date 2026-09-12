class_name CameraPan
extends EventData


func _init(
	time_: float = 0.0,
	side: StringName = &"player",
	ease_string: String = "CLASSIC",
	duration: float = 32.0,
	offset: Vector2 = Vector2.ZERO
) -> void:
	time = time_

	name = &"Camera Pan"
	data[&"side"] = side
	data[&"ease_string"] = ease_string
	data[&"duration"] = duration
	data[&"offset"] = offset

	trigger_before_countdown = true
