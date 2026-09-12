extends Sprite2D


@export var target: Node2D
@export var speed: float = 6.0


func _ready() -> void:
	if is_instance_valid(target):
		global_position = target.global_position


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	global_position = global_position.lerp(
		target.global_position,
		GameUtils.lerp_weight(delta, speed)
	)
