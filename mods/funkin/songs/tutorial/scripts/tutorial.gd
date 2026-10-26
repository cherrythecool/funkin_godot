extends FunkinScript


func _ready() -> void:
	if (not spectator) or (not player):
		queue_free()
		return

	spectator.offset_camera_position(Vector2(0.0, -50.0))

	opponent = spectator
	spectator = null

	camera.position_target = opponent.get_camera_position()
	camera.position = camera.position_target

	game.hud.health_bar.reload_icons()
	opponent.strumline = game.strumlines[&"opponent"]
