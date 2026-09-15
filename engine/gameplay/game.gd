class_name Game
extends Node


static var load_settings: Dictionary[StringName, Variant] = {
	&"mode_name": "Freeplay",
	&"song_name": &"bopeebo",
	&"song_difficulty": &"hard",
	&"songs_folder": "res://mods/funkin/songs",
	&"exit_scene_path": "",
	&"playlist": [] as Array[Dictionary],
}

static var instance: Game = null

@export var strumlines: Dictionary[StringName, StrumlineManager] = {
	&"player": null,
	&"opponent": null,
}

@export var asset_loader: AssetLoader
@export var pause_menu: PackedScene

@export var song_player: AudioStreamPlayer

@export var hud_layer: CanvasLayer

@export var metadata: SongMetadata = null
var chart: Chart = null

var events_index: int = 0

@export var hud: Node

var song_started: bool = false

## Each note type is stored here for use in any note field.
var note_types: Dictionary[StringName, PackedScene] = {}

var playing: bool = true
var scroll_speed: float:
	set(value):
		scroll_speed = value
		scroll_speed_changed.emit(value)

@export var player: Character
@export var opponent: Character
@export var spectator: Character
@export var stage: Stage

var skin: HUDSkin

signal chart_loaded(chart_: Chart)
signal hud_setup
signal ready_post
signal song_start
signal song_finished
signal back_to_menus
signal scroll_speed_changed(value: float)
signal botplay_changed(botplay: bool)
@warning_ignore("unused_signal") signal unpaused


func _init() -> void:
	instance = self


func _ready() -> void:
	randomize()

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Input.use_accumulated_input = false

	MenuAudio.music.stop()

	song_player.stream = Tracks.load_tracks(
		load_settings[&"song_name"],
		load_settings[&"songs_folder"],
	)
	song_player.finished.connect(finish_song.bind(false, false))

	if not song_player.stream:
		printerr("Failed to load tracks for current song! Returning...")
		finish_song(true, false)
		return

	load_chart()
	init_conductor()

	if not metadata:
		var song_folder: String = load_settings[&"songs_folder"]
		var song_name: StringName = load_settings[&"song_name"]
		if ResourceLoader.exists("%s/%s/meta.tres" % [song_folder, song_name]):
			metadata = load("%s/%s/meta.tres" % [song_folder, song_name])
		if not is_instance_valid(metadata):
			metadata = SongMetadata.new()
			metadata.display_name = song_name.to_pascal_case()

	if asset_loader:
		asset_loader.load_assets()

	if &"player" in strumlines:
		if player and not player.strumline:
			player.strumline = strumlines[&"player"]

	if &"opponent" in strumlines:
		if opponent and not opponent.strumline:
			opponent.strumline = strumlines[&"opponent"]

	hud_setup.emit()

	if asset_loader:
		asset_loader.load_scripts(
			load_settings[&"song_name"],
			load_settings[&"songs_folder"],
		)

	ready_post.emit()


func _exit_tree() -> void:
	if instance != self:
		return

	instance = null

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.use_accumulated_input = true


func _process(_delta: float) -> void:
	if not playing:
		return

	if (
		not song_started and
		Conductor.raw_time >= 0.0 and
		Conductor.active and
		not song_player.playing
	):
		start_song()


func _unhandled_input(event: InputEvent) -> void:
	if not playing:
		return

	if event.is_action_pressed(&"game_pause"):
		process_mode = Node.PROCESS_MODE_DISABLED
		Conductor.active = false
		var menu: CanvasLayer = pause_menu.instantiate()
		add_child(menu)
		return
	elif event.is_action_pressed(&"menu_cancel"):
		finish_song(true)

	if event.is_action_pressed(&"toggle_botplay") and strumlines.has(&"player"):
		var plr_strums := strumlines[&"player"]
		plr_strums.cpu = not plr_strums.cpu
		botplay_changed.emit(not plr_strums.cpu)

	if not OS.is_debug_build():
		return
	if event.is_action_pressed(&"skip_time"):
		skip_to(Conductor.raw_time + 10.0)


func start_song(from_position: float = 0.0) -> void:
	song_player.play(from_position)

	Conductor.target_audio = song_player
	Conductor.raw_time = from_position
	Conductor.rate = Conductor.internal_rate

	song_start.emit()
	song_started = true


func finish_song(force: bool = false, sound: bool = true) -> void:
	if not playing:
		return

	song_finished.emit()
	playing = false

	var playlist: Array = load_settings[&"playlist"]
	if not (playlist.is_empty() or force):
		var next_song: Dictionary = playlist.pop_front()
		load_settings[&"song_name"] = next_song[&"name"]
		load_settings[&"song_difficulty"] = next_song[&"difficulty"].to_lower()

		SceneManager.swap_to_file(SongLoader.get_scene_path(
			load_settings[&"song_name"],
			load_settings[&"songs_folder"],
		))
	else:
		if sound:
			MenuAudio.cancel.play()

		back_to_menus.emit()

		var exit_scene: String = load_settings[&"exit_scene_path"]
		if exit_scene.is_empty():
			SceneManager.transition_to_file("uid://bwcdjku7iww5m")
		else:
			SceneManager.transition_to_file(exit_scene)


func load_chart() -> void:
	if not is_instance_valid(chart):
		chart = Chart.load_chart(
			"%s/%s" % [
				load_settings[&"songs_folder"],
				load_settings[&"song_name"],
			],
			load_settings[&"song_difficulty"],
		)

	var custom_speed: float = Settings.get_setting(&"core", "note_scroll_value")
	match Settings.get_setting(&"core", "note_scroll_method"):
		"chart_multiplier":
			scroll_speed = chart.scroll_speed * custom_speed
		"constant":
			scroll_speed = custom_speed

	chart.sort()

	for key: StringName in strumlines:
		if not chart.strumlines.has(key):
			continue

		var manager: StrumlineManager = strumlines[key]
		if not is_instance_valid(manager):
			continue

		manager.key_count = chart.strumlines[key].key_count
		manager.load_notes(chart.strumlines[key].notes)

	chart_loaded.emit(chart)


func init_conductor() -> void:
	Conductor.reset()
	Conductor.append_timing_changes(chart.timing_changes)
	Conductor.calculate_beat()
	Conductor.raw_time = (-4.0 * Conductor.beat_delta) + Conductor.offset
	Conductor.beat_hit.emit.call_deferred(-4)


func skip_to(seconds: float) -> void:
	if not song_started:
		start_song(seconds)
	else:
		if not is_instance_valid(Conductor.target_audio):
			Conductor.raw_time = seconds
		else:
			if is_instance_valid(Conductor.target_audio.stream):
				if seconds >= Conductor.target_audio.stream.get_length():
					finish_song(false, false)
					return

			if not Conductor.target_audio.playing:
				Conductor.target_audio.play(seconds)
			else:
				Conductor.target_audio.seek(seconds)

			Conductor.sync_to_target(0.0)

	Conductor.calculate_beat()

	for key: StringName in strumlines:
		strumlines[key].skip_missed_notes(1.0)
