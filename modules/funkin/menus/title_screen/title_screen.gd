class_name TitleScreen
extends Node2D


static var in_intro: bool = true

@export var randomized_lines: Array[String] = []
@export var hue_shift_material: ShaderMaterial

@onready var conductor: Conductor = %conductor

@onready var post_intro: Node2D = $post_intro
@onready var girlfriend_animation: AnimationPlayer = $post_intro/girlfriend/animation_player
@onready var logo_sprite: AnimatedSprite = $post_intro/logo/sprite
@onready var enter_animation: AnimationPlayer = $post_intro/enter/animation_player
@onready var flash: ColorRect = $flash

@onready var intro_sequence: Node2D = $intro_sequence
@onready var intro_animation: AnimationPlayer = $intro_sequence/animation_player
@onready var intro_alphabet: Alphabet = %alphabet

var transitioning: bool = false
var current_randomized_lines: PackedStringArray = ["Line 1", "Other Lines"]
var flash_tween: Tween
var hue_shift: float = 0.0


func _ready() -> void:
	if not Config.had_user_config:
		Config.had_user_config = true
		SceneManager.swap_to_path("uid://dasf7d5k8p30f")
		return

	var music_player: AudioStreamPlayer = GlobalAudio.music
	if not music_player.playing:
		conductor.reset()
		music_player.play()

	conductor.target_audio = music_player
	conductor.tempo = 102.0

	if in_intro:
		start_intro()
		post_intro.visible = false
	else:
		intro_sequence.queue_free()
		post_intro.visible = true

	conductor.beat_hit.connect(_on_beat_hit)
	conductor.calculate_beat()


func _process(delta: float) -> void:
	if not is_instance_valid(hue_shift_material):
		return

	var swag_axis: float = Input.get_axis(&"ui_left", &"ui_right")
	hue_shift += swag_axis * delta * 0.1
	hue_shift_material.set_shader_parameter(&"value", hue_shift)


func _input(event: InputEvent) -> void:
	if transitioning or event.is_echo() or not event.is_pressed():
		return
	if event.is_action(&"ui_cancel") and not Global.is_mobile:
		get_tree().quit()
	if event.is_action(&"ui_accept"):
		if in_intro:
			skip_intro()
		else:
			transitioning = true
			GlobalAudio.get_player(^"MENU/CONFIRM").play()

			if Config.get_value("accessibility", "flashing_lights"):
				flash.color = Color.WHITE
			else:
				flash.color = Color.TRANSPARENT
				enter_animation.speed_scale = 0.0

			enter_animation.play(&"press")

			flash_tween = GameUtils.replace_tween(self, flash_tween)
			flash_tween.tween_property(flash, ^"color:a", 0.0, 1.0)
			flash_tween.tween_callback(SceneManager.transition_to_file.bind("uid://b7fwxsepnt38j"))


func _on_beat_hit(beat: int) -> void:
	girlfriend_animation.play(&"dance_%s" % ["left" if beat % 2 == 0 else "right"])
	logo_sprite.play(&"bump")
	logo_sprite.frame = 0

	if not in_intro:
		return

	if beat >= int(intro_animation.current_animation_length):
		skip_intro()
		return

	var previous: String = intro_alphabet.text
	intro_animation.seek(float(beat), true)
	intro_alphabet.horizontal_alignment = "Center"

	match intro_alphabet.text:
		"!random":
			if current_randomized_lines.is_empty():
				intro_alphabet.text = ""
			else:
				intro_alphabet.text = current_randomized_lines[0]
		"!randomall":
			intro_alphabet.text = ""

			for line: String in current_randomized_lines:
				intro_alphabet.text += line + "\n"

			# le funni
			if intro_alphabet.text.begins_with("#include"):
				intro_alphabet.horizontal_alignment = "Left"
		"!keep":
			intro_alphabet.text = previous


func start_intro() -> void:
	intro_animation.play(&"intro")

	if randomized_lines.is_empty():
		return

	var index: int = randi_range(0, randomized_lines.size() - 1)
	current_randomized_lines = randomized_lines[index].replace("--", "\n").split("\n")


func skip_intro() -> void:
	in_intro = false
	intro_sequence.hide()
	intro_sequence.queue_free()

	post_intro.visible = true

	flash.color = Color.WHITE
	flash_tween = GameUtils.replace_tween(self, flash_tween)
	flash_tween.tween_property(flash, ^"color:a", 0.0, 1.0)
