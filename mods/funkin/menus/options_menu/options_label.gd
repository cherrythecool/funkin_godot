@tool
extends AnimatedSprite


var timer: float = 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	timer += delta
	rotation_degrees = sin(timer) * 4.0
	offset.y = cos(timer) * 4.0
	scale = scale.lerp(Vector2(0.6, 0.6), GameUtils.lerp_weight(delta, 4.5))
