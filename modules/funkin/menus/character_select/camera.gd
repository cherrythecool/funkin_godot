extends Camera2D


@export var smoothed_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_process(0.0)
	reset_smoothing()
	force_update_scroll()


func _process(_delta: float) -> void:
	position = Global.game_size / 2.0
	position += get_local_mouse_position() * 0.03
	position += smoothed_offset
