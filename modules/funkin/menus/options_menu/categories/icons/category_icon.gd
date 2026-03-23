extends Control
class_name CategoryIcon


@export var category: PackedScene = null
@onready var sprite: AnimatedSprite = $sprite

var target_alpha: float = 0.6
var target_scale: float = 0.8


func _ready() -> void:
	if category == null:
		category = load("uid://di58m2bnkbajd")

	sprite.modulate.a = target_alpha
	sprite.scale = Vector2.ONE * target_scale


func _process(delta: float) -> void:
	sprite.modulate.a = lerpf(
		sprite.modulate.a,
		target_alpha,
		GameUtils.lerp_weight(delta, 9.0),
	)

	sprite.scale = sprite.scale.lerp(
		Vector2.ONE * target_scale,
		GameUtils.lerp_weight(delta, 10.0),
	)
