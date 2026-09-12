extends Node2D


static var selected_x: int = 1
static var selected_y: int = 1

@export var entries: Dictionary[StringName, CharacterSelectEntry] = {}

@export_group("References")
@export var camera_2d: Camera2D
@export var fade_rect: ColorRect
@export var speakers: AnimateSymbol2D

@export_subgroup("HUD")
@export var character_selector: Node2D
@export var choose_dipshit: Sprite2D
@export var dipshit_backing: AnimatedSprite
@export var character_options: Node2D
@export var selector: AnimatedSprite

@export_subgroup("Characters on Stage")
@export var title: Sprite2D
@export var characters_parent: Node2D
@export var player: AnimateSymbol2D
@export var spectator: AnimateSymbol2D

@export_subgroup("Sounds")
@export var music: AudioStreamPlayer
@export var scroll: AudioStreamPlayer
@export var confirm: AudioStreamPlayer
@export var cancel: AudioStreamPlayer

var title_tween: Tween
var spectator_anim: AnimationPlayer
var player_anim: AnimationPlayer

# TODO: just use a state variable or smth bro
var locked: bool = false
var transitioning: bool = false

var dipshit_tween: Tween
var music_tween: Tween

var start_freeplay: String


func _ready() -> void:
	var current_icon: Node2D = character_options.get_child(selected_x + (selected_y * 3))
	selector.global_position = current_icon.global_position
	MenuAudio.music.stop()
	start_freeplay = MainMenu.freeplay_scene

	confirm.finished.connect(_on_confirm_finished)

	Conductor.reset()
	Conductor.target_audio = music
	Conductor.tempo = 90.0
	Conductor.beat_hit.connect(_on_beat_hit)

	music.volume_linear = 0.0
	music.play()

	music_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	music_tween.tween_property(music, ^"volume_linear", 1.0, 1.0)

	dipshit_tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO)\
			.set_ease(Tween.EASE_OUT).set_parallel()
	character_selector.position.y += 220.0
	dipshit_tween.tween_property(character_selector, ^'position:y',
			character_selector.position.y - 220.0, 1.2)

	dipshit_backing.position.y -= 10.0
	dipshit_tween.tween_property(dipshit_backing, ^'position:y',
			dipshit_backing.position.y + 10.0, 1.1)

	choose_dipshit.position.y -= 20.0
	dipshit_tween.tween_property(choose_dipshit, ^'position:y',
			choose_dipshit.position.y + 20.0, 1.0)

	spectator_anim = spectator.get_node(^'AnimationPlayer')
	spectator_anim.play(&'enter')

	player_anim = player.get_node(^'AnimationPlayer')
	player_anim.play(&'enter')

	_update_selection(false)

	if "smoothed_offset" in camera_2d:
		camera_2d.smoothed_offset = get_camera_offset()


func _exit_tree() -> void:
	# just in case we exit the menu while the tween is still
	# running on the SceneTree, i guess?
	if is_instance_valid(dipshit_tween):
		dipshit_tween.kill()


func _process(delta: float) -> void:
	for i: int in character_options.get_child_count():
		var icon: Node2D = character_options.get_child(i)
		if i == selected_x + (selected_y * 3):
			selector.global_position = selector.global_position.lerp(icon.global_position, GameUtils.lerp_weight(delta, 12.0))
			icon.scale = icon.scale.lerp(Vector2.ONE * 1.15, GameUtils.lerp_weight(delta, 9.0))
		else:
			icon.scale = icon.scale.lerp(Vector2.ONE, GameUtils.lerp_weight(delta, 9.0))

	if "smoothed_offset" in camera_2d:
		camera_2d.smoothed_offset = get_camera_offset()


func _unhandled_input(event: InputEvent) -> void:
	if transitioning:
		return
	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action(&'menu_cancel'):
		if locked:
			if music_tween and music_tween.is_running():
				music_tween.kill()

			music_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
			music_tween.tween_property(music, ^"volume_linear", 1.0, 2.0)

			locked = false
			cancel.play()
			selector.play(&'denied')
			player_anim.play(&'cancel')
			spectator_anim.play(&'cancel')
			confirm.stop()

			var index: int = selected_x + (selected_y * 3)
			# TODO: make this a script or smth so better customization
			var icon: AnimatedSprite = character_options.get_child(index)
			icon.playing = false
			icon.frame = 0

			await spectator_anim.animation_finished

			selector.play(&'idle')
		else:
			if ResourceLoader.exists(start_freeplay):
				SceneManager.transition_to_file(start_freeplay)
			else:
				SceneManager.transition_to_file('uid://b7fwxsepnt38j')
	if event.is_action(&'menu_accept') and not locked:
		locked = true

		var index: int = selected_x + (selected_y * 3)

		var icon: Node = character_options.get_child(index)
		var key: StringName = icon.get_meta(&"key", &"locked")
		if key not in entries:
			key = &"locked"

		if key == &"locked":
			locked = false
			selector.play(&'denied')
			selector.set_frame_and_progress(0, 0.0)
			cancel.play()
		else:
			finish_selection(icon, entries[key].freeplay_path)

	# TODO: make this cleaner
	if locked:
		return

	if event.is_action(&'menu_left'):
		selected_x = wrapi(selected_x - 1, 0, 3)
		_update_selection()
	if event.is_action(&'menu_right'):
		selected_x = wrapi(selected_x + 1, 0, 3)
		_update_selection()
	if event.is_action(&'menu_up'):
		selected_y = wrapi(selected_y - 1, 0, 3)
		_update_selection()
	if event.is_action(&'menu_down'):
		selected_y = wrapi(selected_y + 1, 0, 3)
		_update_selection()


func _update_selection(sound: bool = true) -> void:
	selector.play(&'idle')

	if sound:
		scroll.play()

	var index: int = selected_x + (selected_y * 3)

	var icon: Node = character_options.get_child(index)
	var key: StringName = icon.get_meta(&"key", &"locked")
	if key not in entries:
		key = &"locked"

	_load_characters(entries[key].player, entries[key].spectator, entries[key].name_texture)

	if entries[key].player == entries[key].spectator:
		spectator.process_mode = Node.PROCESS_MODE_DISABLED
		spectator.hide()


func get_camera_offset() -> Vector2:
	return Vector2(
		10.0 * float(selected_x - 1),
		8.0 * float(selected_y - 1),
	)


func finish_selection(icon: AnimatedSprite, scene_path: String) -> void:
	MainMenu.freeplay_scene = scene_path

	if music_tween and music_tween.is_running():
		music_tween.kill()

	music_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	music_tween.tween_property(music, ^"volume_linear", 0.0, 1.0)

	confirm.play()
	player_anim.play(&'confirm')
	spectator_anim.play(&'confirm')
	selector.play(&'confirm')
	icon.playing = true


func _on_confirm_finished() -> void:
	if not locked:
		return

	transitioning = true

	if not Settings.get_setting(&"core", "skip_scene_transitions"):
		camera_2d.set_script(null)
		camera_2d.limit_enabled = false

		var alpha_tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		alpha_tween.tween_property(fade_rect, ^"color:a", 1.0, 0.5).set_delay(0.7)

		var camera_tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT)
		camera_tween.tween_property(camera_2d, ^"offset:y", 30.0, 0.5).set_trans(Tween.TRANS_SINE)
		camera_tween.tween_property(camera_2d, ^"offset:y", -150.0, 0.7).set_trans(Tween.TRANS_QUAD)
		await camera_tween.finished

	FreeplayMenu.index = 0
	FreeplayMenu.difficulty_index = 0

	SceneManager.transition_to_file(MainMenu.freeplay_scene)


func _load_characters(player_scene: PackedScene, spectator_scene: PackedScene, logo: Texture2D) -> void:
	title.texture = logo
	if is_instance_valid(title_tween) and title_tween.is_running():
		title_tween.kill()

	title.offset.y = -60.0
	title.scale.x = 0.77 * 0.9
	title.scale.y = 0.77 * 1.1
	title.material.set_shader_parameter("block_size", Vector2.ONE * 4.0)
	title_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE).set_parallel()
	title_tween.tween_property(title, ^"offset:y", 0.0, 0.4)
	title_tween.tween_property(title, ^"scale", Vector2.ONE * 0.77, 0.5)
	title_tween.tween_property(title.material, ^"shader_parameter/block_size", Vector2.ONE, 0.5)

	spectator.queue_free()
	player.queue_free()

	var spectator_node: Node = spectator_scene.instantiate()
	characters_parent.add_child(spectator_node)
	spectator = spectator_node

	var player_node: Node = player_scene.instantiate()
	characters_parent.add_child(player_node)
	player = player_node

	spectator_anim = spectator.get_node(^'AnimationPlayer')
	spectator_anim.play(&'enter')
	player_anim = player.get_node(^'AnimationPlayer')
	player_anim.play(&'enter')


func _on_beat_hit(beat: int) -> void:
	speakers.play()
	speakers.set_frame_and_progress(0, 0.0)

	if not locked:
		if player_anim.current_animation == &"":
			if player_anim.has_animation(&'idle'):
				player_anim.play(&'idle')

		if spectator_anim.has_animation(&'dance_left') and (
			spectator_anim.current_animation == &"" or
			spectator_anim.current_animation.begins_with(&"dance_")
		):
			spectator_anim.play(&'dance_left' if beat % 2 == 0 else &'dance_right')
		elif spectator_anim.current_animation == &"":
			if spectator_anim.has_animation(&"idle"):
				spectator_anim.play(&"idle")
