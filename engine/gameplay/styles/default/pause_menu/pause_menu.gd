class_name PauseMenu
extends CanvasLayer


@export_file("*.tscn") var options_menu_path: String = "uid://c8yym7pblb4yp"
@export var music: AudioStreamPlayer

@export var background: Control
@export var song_info: Alphabet
@export var mode_label: Alphabet

@export var options: Node2D

var active: bool = true
var selected: int = 0


static func _on_options_scene_changed(previous_scene: String) -> void:
	if "target_scene" in SceneManager.current_scene:
		SceneManager.current_scene.target_scene = previous_scene


func _ready() -> void:
	Engine.time_scale = 1.0
	change_selection()

	background.modulate.a = 0.5
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(background, ^"modulate:a", 1.0, 0.5)

	create_tween().tween_property(music, ^"volume_linear", 0.9, 2.0).set_delay(0.5)

	if not Game.instance:
		return

	if Game.instance.hud and Game.instance.hud.get(&"hud_skin"):
		music.stream = Game.instance.hud.hud_skin.pause_music
		music.play()

	song_info.text = "%s\n(%s)" % [Game.instance.metadata.get_full_name(),
			Game.load_settings[&"song_difficulty"].to_upper(),]
	if song_info.size.x > Global.game_size.x:
		song_info.scale = Vector2.ONE * (Global.game_size.x / song_info.size.x * 0.9)
	song_info.position.x = Global.game_size.x - \
			(float(song_info.size.x) * song_info.scale.x) - 16.0
	mode_label.text = Game.load_settings[&"mode_name"].to_upper()
	mode_label.position = Global.game_size - (Vector2(mode_label.size) * 0.75) - \
			Vector2(16.0, 16.0)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action_pressed(&"menu_down") or event.is_action_pressed(&"menu_up"):
		change_selection(roundi(Input.get_axis(&"menu_up", &"menu_down")))
	if event.is_action_pressed(&"menu_accept"):
		for option: ListedAlphabet in options.get_children():
			if option.target_y == 0:
				select(option.name.to_lower())
				return


func change_selection(amount: int = 0) -> void:
	selected = wrapi(selected + amount, 0, options.get_child_count())

	if amount != 0:
		MenuAudio.scroll.play()
	for i: int in options.get_child_count():
		var option: ListedAlphabet = options.get_child(i)
		option.target_y = i - selected
		option.modulate.a = 1.0 if option.target_y == 0 else 0.6


func select(option: StringName) -> void:
	match option:
		&"resume":
			close()
		&"restart":
			close()
			SceneManager.reload_current_scene()
		&"options":
			close()
			Game.instance.back_to_menus.emit()

			var previous_scene := get_tree().current_scene.scene_file_path
			SceneManager.scene_changed.connect(_on_options_scene_changed.bind(previous_scene), CONNECT_ONE_SHOT)
			SceneManager.transition_to_file(options_menu_path)
		&"quit":
			close()
			Game.instance.finish_song(true)
		_:
			printerr("Pause Option %s unimplemented." % option)


func close(was_input: bool = true) -> void:
	if was_input:
		get_viewport().set_input_as_handled()

	hide()
	active = false

	if was_input:
		unpause.call_deferred()
	else:
		unpause()

	if was_input:
		queue_free()


func unpause() -> void:
	if is_instance_valid(Conductor.instance):
		Engine.time_scale = Conductor.instance.rate

	if is_instance_valid(Game.instance):
		Game.instance.process_mode = Node.PROCESS_MODE_INHERIT
		Conductor.active = true
		Game.instance.unpaused.emit()


func _exit_tree() -> void:
	close(false)
