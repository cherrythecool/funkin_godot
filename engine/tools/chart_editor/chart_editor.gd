extends Control


static var chart: Chart
static var metadata: SongMetadata
static var last_play_time: float = -1

signal chart_loaded
signal time_shifted
signal snap_changed(value: float)

@export var song_player: AudioStreamPlayer
@export var strumlines: HBoxContainer
@export var note_snap_option: OptionButton

@export var song_name: StringName = &"bopeebo_erect"
@export var difficulty: StringName = &"nightmare"
@export var songs_folder: String = "res://mods/funkin/songs/"

var note_snapping: float = 1.0
var strumline_scene: PackedScene = load("uid://cqfutljqtrg70")


func _ready() -> void:
	if not chart:
		chart = Chart.load_chart(
			"%s/%s" % [
				songs_folder,
				song_name,
			],
			difficulty,
		)
		metadata = SongMetadata.load_from_song(song_name, songs_folder)

	if chart:
		chart_loaded.connect(_on_chart_loaded)
		chart_loaded.emit()

	MenuSounds.music.stop()
	song_player.stream = Tracks.load_tracks(
		song_name,
		songs_folder,
	)
	song_player.finished.connect(_on_song_finished)
	snap_changed.emit(note_snapping)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventPanGesture:
		if event.delta.abs().y > 0.0:
			shift_time(-event.delta.y * Conductor.beat_delta)

	if event.is_action_pressed(&"chart_playtest"):
		Game.load_settings[&"chart"] = chart
		Game.load_settings[&"chart_keep"] = true
		Game.load_settings[&"songs_folder"] = songs_folder
		Game.load_settings[&"song_name"] = song_name
		Game.load_settings[&"song_difficulty"] = difficulty.to_lower()
		Game.load_settings[&"mode_name"] = "Chart Playtest"
		Game.load_settings[&"exit_scene_path"] = get_tree().current_scene.scene_file_path
		Game.load_settings[&"playlist"].clear()

		last_play_time = Conductor.raw_time
		if Input.is_action_pressed(&"shift"):
			Game.load_settings[&"start_time"] = last_play_time

		SceneManager.transition_to_file(SongLoader.get_scene_path(song_name, songs_folder))
		Conductor.active = true

	if event.is_action_pressed(&"chart_play_pause"):
		if (not song_player.playing) and (not song_player.stream_paused):
			if Conductor.raw_time < Conductor.target_length:
				song_player.play(Conductor.raw_time)
				Conductor.active = true
		else:
			song_player.stream_paused = not song_player.stream_paused
			Conductor.active = not song_player.stream_paused

	if event.is_action_pressed(&"chart_scroll_up"):
		shift_time(-Conductor.beat_delta / 4.0)
	if event.is_action_pressed(&"chart_scroll_down"):
		shift_time(Conductor.beat_delta / 4.0)


func shift_time(amount: float) -> void:
	if Conductor.active:
		Conductor.active = false
		Conductor.target_audio.stream_paused = true

	Conductor.raw_time = clampf(Conductor.raw_time + amount, 0.0, Conductor.target_length)
	Conductor.calculate_beat()
	Conductor.target_audio.stop()
	Conductor.target_audio.seek(Conductor.raw_time)
	time_shifted.emit()


func _on_chart_loaded() -> void:
	Conductor.reset()
	Conductor.target_audio = song_player
	Conductor.append_timing_changes(chart.timing_changes)
	Conductor.active = false

	if last_play_time != -1:
		Conductor.raw_time = last_play_time
		Conductor.target_audio.play(Conductor.raw_time)
		Conductor.target_audio.stream_paused = true
		Conductor.calculate_beat()
		last_play_time = -1

	if not strumlines:
		return

	FunkinUtils.free_children_from(strumlines)

	for strumline_key: StringName in chart.strumlines:
		var strumline := chart.strumlines[strumline_key]
		var strumline_node: Node = strumline_scene.instantiate()
		strumline_node.target = strumline
		strumline_node.target_key = strumline_key
		time_shifted.connect(strumline_node._on_time_shifted)
		snap_changed.connect(strumline_node._on_snap_changed)
		strumlines.add_child(strumline_node)


func _on_song_finished() -> void:
	song_player.stream_paused = true
	Conductor.active = false
	Conductor.raw_time = Conductor.target_length
	Conductor.calculate_beat()


func _on_note_snap_option_selected(index: int) -> void:
	note_snapping = 16.0 / float(note_snap_option.get_item_text(index))
	snap_changed.emit(note_snapping)
