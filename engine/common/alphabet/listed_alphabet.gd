@tool
class_name ListedAlphabet
extends Alphabet


@export var target_y: int = 0
@export var rate: float = 9.6
@export var use_x: bool = true
@export var offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	super()

	position = get_target_position()


func _process(delta: float) -> void:
	position = position.lerp(
		get_target_position(),
		GameUtils.lerp_weight(delta, rate),
	)


func get_target_position() -> Vector2:
	# 156 = 120 * 1.3
	return Vector2(
		(target_y * 20.0 + 90.0) * float(use_x),
		target_y * 156.0 + 360.0 - size.y * 0.5,
	) + offset
