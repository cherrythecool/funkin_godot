class_name FunkinGameOver
extends Node2D


static var character_path: String = "uid://w4v0gymuehdt"
static var character_position: Vector2 = Vector2.ZERO

@export_group("Audio Players")
@export var music: AudioStreamPlayer
@export var on_death: AudioStreamPlayer
@export var retry: AudioStreamPlayer

@onready var camera: FunkinCamera2D = %camera_2d

@onready var initial_focus_timer: Timer = %initial_focus_timer
@onready var fade_out_delay: Timer = %fade_out_delay

var character: CanvasItem
var active: bool


func _ready() -> void:
	active = true

	Conductor.reset()
	Conductor.target_audio = music

	initial_focus_timer.timeout.connect(_on_initial_focus_timer_timeout)
	fade_out_delay.timeout.connect(_on_fade_out_timer_timeout)

	initial_focus_timer.start()

	if not ResourceLoader.exists(character_path):
		character_path = "uid://w4v0gymuehdt"

	character = load(character_path).instantiate()
	character.position = character_position

	if "gameover_assets" in character and character.gameover_assets:
		var assets: GameoverAssets = character.gameover_assets
		if assets.on_death:
			on_death.stream = assets.on_death

		if assets.looping_music:
			music.stream = assets.looping_music

		if assets.retry:
			retry.stream = assets.retry

	add_child(character)

	if character is Character and character.has_anim(&"death"):
		character.play_anim(&"death")
		character.animation_finished.connect(_on_animation_finished)
		on_death.play()
		return

	on_death.finished.connect(_on_animation_finished.bind(&"death"))
	on_death.play()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed(&"menu_cancel"):
		active = false
		GlobalAudio.get_player(^"MENU/CANCEL").play()
		FunkinCamera2D.reset_persistent_values()
		SceneManager.transition_to_file(Game.load_settings[&"exit_scene_path"])

	if event.is_action_pressed(&"menu_accept"):
		active = false

		if character is Character:
			character.play_anim(&"retry")

		music.stop()
		retry.play()
		fade_out_delay.start()


func _on_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		&"death":
			music.play()

			if character is Character:
				character.play_anim(&"loop")


func _on_initial_focus_timer_timeout() -> void:
	camera.position_lerps = true

	if character is Character:
		camera.position_target = character.get_camera_position()
	else:
		camera.position_target = character.position


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
