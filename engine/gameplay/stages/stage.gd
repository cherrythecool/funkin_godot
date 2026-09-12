class_name Stage
extends FunkinScript


@export_range(0.01, 4.0, 0.001) var default_zoom: float = 1.05
@export_range(0.0, 10.0, 0.001) var camera_speed: float = 1.0

@export_group("Spawn Points", "spawn_")
@export var spawn_spectator: CharacterPlacement
@export var spawn_player: CharacterPlacement
@export var spawn_opponent: CharacterPlacement
