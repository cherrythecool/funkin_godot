extends Control


@export_dir var songs_folder: String = "res://mods/funkin/songs"
@export var weeks: Array[StoryMenuWeek] = []

@export_group("References")
@export var weeks_container: VBoxContainer
@export var difficulty_options: OptionButton
@export var songs_label: Label
@export var high_score_label: Label

var difficulty: StringName
var current_week: StoryMenuWeek


func _ready() -> void:
	for week: StoryMenuWeek in weeks:
		var button := Button.new()
		button.name = week.title
		button.text = week.title
		button.pressed.connect(select_week.bind(week))
		weeks_container.add_child(button)


func select_week(week: StoryMenuWeek) -> void:
	current_week = week

	var display_names: Array[StringName]
	display_names.resize(week.songs.size())

	for i: int in week.songs.size():
		var song_name := week.songs[i]
		display_names[i] = SongMetadata.load_from_song(song_name, songs_folder).get_full_name()

	songs_label.text = ", ".join(display_names)
	difficulty_options.clear()

	for diff: StringName in current_week.difficulties:
		difficulty_options.add_item(diff)

	if current_week.difficulties.size() > 0:
		_on_difficulty_option_selected(0)


func play_songs() -> void:
	if current_week.songs.is_empty():
		printerr("Can't play empty week")
		return

	var first_song := current_week.songs[0]
	var first_meta := SongMetadata.load_from_song(first_song, songs_folder)
	var song_name := first_meta.get_override_name(first_song, difficulty)

	Game.load_settings[&"songs_folder"] = songs_folder
	Game.load_settings[&"song_name"] = song_name
	Game.load_settings[&"song_difficulty"] = difficulty.to_lower()
	Game.load_settings[&"mode_name"] = "Story Mode"
	Game.load_settings[&"exit_scene_path"] = get_tree().current_scene.scene_file_path
	Game.load_settings[&"playlist"].clear()

	if current_week.songs.size() > 1:
		for i: int in range(1, current_week.songs.size()):
			var song := current_week.songs[i]
			var meta := SongMetadata.load_from_song(song, songs_folder)
			var entry: Dictionary[StringName, StringName] = {
				&"name": meta.get_override_name(song, difficulty),
				&"difficulty": difficulty,
			}

			Game.load_settings[&"playlist"].push_back(entry)

	SceneManager.transition_to_file(SongLoader.get_scene_path(song_name, songs_folder))


func _on_difficulty_option_selected(index: int) -> void:
	difficulty = difficulty_options.get_item_text(index)

	var songs: Array[StringName] = []
	for song_name: StringName in current_week.songs:
		var meta := SongMetadata.load_from_song(song_name, songs_folder)
		songs.append(meta.get_override_name(song_name, difficulty))

	var high_score := Highscores.get_collective_score(songs, difficulty)
	if str(high_score.get("score")) == "N/A":
		high_score_label.text = "High Score: N/A\nMisses: N/A"
	else:
		high_score_label.text = "High Score: %d\nMisses: %d" % [
			high_score.get("score"),
			high_score.get("misses"),
		]
