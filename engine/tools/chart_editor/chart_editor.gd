extends Control


signal chart_loaded
signal time_shifted

@export var song_player: AudioStreamPlayer
@export var strumlines: HBoxContainer

@export var song_name: StringName = &"bopeebo_erect"
@export var difficulty: StringName = &"nightmare"
@export var songs_folder: String = "res://mods/funkin/songs/"

var chart: Chart
var metadata: SongMetadata
var strumline_scene: PackedScene = load("uid://cqfutljqtrg70")


func _ready() -> void:
	chart = Chart.load_chart(
		"%s/%s" % [
			songs_folder,
			song_name,
		],
		difficulty,
	)
	metadata = SongMetadata.load_from_song(song_name, songs_folder)

	chart_loaded.connect(_on_chart_loaded)
	chart_loaded.emit()

	MenuSounds.music.stop()
	song_player.stream = Tracks.load_tracks(
		song_name,
		songs_folder,
	)
	song_player.finished.connect(_on_song_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"chart_play_pause"):
		if (not song_player.playing) and (not song_player.stream_paused):
			if Conductor.raw_time < Conductor.target_length:
				song_player.play(Conductor.raw_time)
				Conductor.active = true
		else:
			song_player.stream_paused = not song_player.stream_paused
			Conductor.active = not song_player.stream_paused

	if event is InputEventPanGesture:
		if event.delta.abs().y > 0.0:
			shift_time(-event.delta.y * Conductor.beat_delta)

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

	if not strumlines:
		return

	FunkinUtils.free_children_from(strumlines)

	for strumline_key: StringName in chart.strumlines:
		var strumline := chart.strumlines[strumline_key]
		var strumline_node: Node = strumline_scene.instantiate()
		strumline_node.target = strumline
		strumline_node.target_key = strumline_key
		time_shifted.connect(strumline_node._on_time_shifted)
		strumlines.add_child(strumline_node)


func _on_song_finished() -> void:
	song_player.stream_paused = true
	Conductor.active = false
	Conductor.raw_time = Conductor.target_length
	Conductor.calculate_beat()
