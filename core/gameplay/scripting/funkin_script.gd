class_name FunkinScript
extends Node


var conductor: Conductor:
	get:
		if is_instance_valid(Conductor.instance):
			return Conductor.instance
		else:
			return null

var game: Game:
	get:
		if is_instance_valid(Game.instance):
			return Game.instance
		else:
			return null

var player: Character:
	set(value):
		if is_instance_valid(game):
			game.player = value
	get:
		if is_instance_valid(game):
			return game.player
		else:
			return null

var opponent: Character:
	set(value):
		if is_instance_valid(game):
			game.opponent = value
	get:
		if is_instance_valid(game):
			return game.opponent
		else:
			return null

var spectator: Character:
	set(value):
		if is_instance_valid(game):
			game.spectator = value
	get:
		if is_instance_valid(game):
			return game.spectator
		else:
			return null

var stage: Stage:
	set(value):
		if is_instance_valid(game):
			game.stage = value
	get:
		if is_instance_valid(game):
			return game.stage
		else:
			return null

var camera: GameCamera2D:
	get:
		if is_instance_valid(GameCamera2D.instance):
			return GameCamera2D.instance
		else:
			return null


func _init() -> void:
	await tree_entered
	_initialize_variables()


func _ready_post() -> void:
	pass


func _process_post(_delta: float) -> void:
	pass


func _on_beat_hit(_beat: int) -> void:
	pass


func _on_step_hit(_step: int) -> void:
	pass


func _on_measure_hit(_measure: int) -> void:
	pass


func _on_song_start() -> void:
	pass


func _on_song_finished() -> void:
	pass


func _on_back_to_menus() -> void:
	pass


func _on_event_prepare(_event: EventData) -> void:
	pass


func _on_event_hit(_event: EventData) -> void:
	pass


func _initialize_variables() -> void:
	if is_instance_valid(conductor):
		conductor.beat_hit.connect(_on_beat_hit)
		conductor.step_hit.connect(_on_step_hit)
		conductor.measure_hit.connect(_on_measure_hit)

	if is_instance_valid(game):
		game.song_start.connect(_on_song_start)
		game.song_finished.connect(_on_song_finished)
		game.back_to_menus.connect(_on_back_to_menus)
		game.event_prepare.connect(_on_event_prepare)
		game.event_hit.connect(_on_event_hit)
		game.ready_post.connect(_ready_post)
		#game.process_post.connect(_process_post)
