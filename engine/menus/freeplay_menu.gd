extends Control


@export_dir var songs_folder: String = "res://mods/funkin/songs"
@export var songs: Array[StringName] = []

@export_group("References")
@export var songs_container: VBoxContainer
@export var difficulty_options: OptionButton
@export var song_label: Label
@export var high_score_label: Label

var song: StringName
var difficulty: StringName
var song_metadata: SongMetadata


func _ready() -> void:
	for song_name: StringName in songs:
		var meta := SongMetadata.load_from_song(song_name, songs_folder)
		var button := Button.new()
		button.name = song_name
		button.text = meta.get_full_name()
		button.pressed.connect(select_song.bind(song_name, meta))
		songs_container.add_child(button)


func select_song(song_name: StringName, meta: SongMetadata) -> void:
	song = song_name
	song_metadata = meta
	song_label.text = song_metadata.get_full_name()

	difficulty_options.clear()

	for diff: StringName in meta.difficulties:
		difficulty_options.add_item(diff)

	if meta.difficulties.size() > 0:
		_on_difficulty_option_selected(0)


func play_song() -> void:
	var song_name := song_metadata.get_override_name(song, difficulty)
	Game.load_settings[&"songs_folder"] = songs_folder
	Game.load_settings[&"song_name"] = song_name
	Game.load_settings[&"song_difficulty"] = difficulty.to_lower()
	Game.load_settings[&"mode_name"] = "Freeplay"
	Game.load_settings[&"exit_scene_path"] = get_tree().current_scene.scene_file_path
	Game.load_settings[&"playlist"].clear()
	SceneManager.transition_to_file(SongLoader.get_scene_path(song_name, songs_folder))


func _on_difficulty_option_selected(index: int) -> void:
	difficulty = difficulty_options.get_item_text(index)

	var high_score := Highscores.get_score(song, difficulty)
	if str(high_score.get("score", "N/A")) == "N/A":
		high_score_label.text = "High Score: N/A\nMisses: N/A\nAccuracy: N/A\nRank: N/A"
	else:
		high_score_label.text = "High Score: %d\nMisses: %d\nAccuracy: %.2f%%\nRank: %s" % [
			high_score.get("score", 0),
			high_score.get("misses", 0),
			high_score.get("accuracy", 0.0),
			high_score.get("rank", "F"),
		]
