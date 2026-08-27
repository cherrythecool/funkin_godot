extends Node2D


static var character_position: Vector2 = Vector2.ZERO
static var character_path: String = "uid://w4v0gymuehdt"

@onready var camera: GameCamera2D = %camera_2d
@onready var initial_focus_timer: Timer = %initial_focus_timer
@onready var fade_out_delay: Timer = %fade_out_delay

@onready var music_player: AudioStreamPlayer = %music
@onready var on_death: AudioStreamPlayer = %on_death
@onready var retry: AudioStreamPlayer = %retry

var character: Character
var active: bool = true


func _ready() -> void:
	active = true

	Conductor.reset()
	Conductor.target_audio = music_player

	initial_focus_timer.start()

	if not ResourceLoader.exists(character_path):
		character_path = "uid://w4v0gymuehdt"

	character = load(character_path).instantiate()

	if is_instance_valid(character.gameover_assets):
		var assets := character.gameover_assets
		if is_instance_valid(assets.on_death):
			on_death.stream = assets.on_death
		if is_instance_valid(assets.looping_music):
			music_player.stream = assets.looping_music
		if is_instance_valid(assets.retry):
			retry.stream = assets.retry

	add_child(character)
	character.global_position = character_position
	if character.has_anim(&"death"):
		character.play_anim(&"death")
		character.animation_finished.connect(_on_animation_finished)
		on_death.play()
	else:
		on_death.finished.connect(_on_animation_finished.bind(&"death"))
		on_death.play()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed(&"menu_cancel"):
		active = false
		GlobalAudio.get_player(^"MENU/CANCEL").play()
		GameCamera2D.reset_persistent_values()
		SceneManager.transition_to_file(Game.load_settings[&"exit_scene_path"])

	if event.is_action_pressed(&"menu_accept"):
		active = false
		character.play_anim(&"retry")
		music_player.stop()
		retry.play()
		fade_out_delay.start()


func _on_animation_finished(animation: StringName) -> void:
	match animation:
		&"death":
			character.play_anim(&"loop")
			music_player.play()


func _on_initial_focus_timer_timeout() -> void:
	camera.position_lerps = true
	camera.position_target = character.get_camera_position()


func _on_fade_out_timer_timeout() -> void:
	var tween := create_tween()
	tween.tween_property(character, ^"modulate:a", 0.0, 2.0)
	tween.tween_callback(func() -> void:
		SceneManager.transition_to_file(
			SongLoader.get_scene_path(
				Game.load_settings[&"song_name"],
				Game.load_settings[&"songs_folder"],
			),
		)
	)
