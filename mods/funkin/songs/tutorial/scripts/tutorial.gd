extends FunkinScript


func _ready() -> void:
	if not (is_instance_valid(spectator) and is_instance_valid(player)):
		queue_free()
		return

	spectator.offset_camera_position(Vector2(0.0, -50.0))

	if opponent.name == &"null":
		opponent = spectator
		spectator = null

		camera.position_target = opponent.get_camera_position()
		camera.position = camera.position_target

		game.hud.health_bar.reload_icons()
		opponent.strumline = game.strumlines[&"opponent"]
