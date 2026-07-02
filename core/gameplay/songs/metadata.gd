class_name SongMetadata
extends Resource


@export_group("Display Info")
@export var display_name: StringName = &"Song Name"
@export var mix: StringName = &"Default"
@export var icon: Icon = null

@export_group("Difficulties")
@export var difficulties: PackedStringArray = [
	"easy", "normal", "hard",
]
@export var difficulty_song_overrides: Dictionary[String, StringName] = {}

@export_group("Game Properties")
@export var skip_countdown: bool = false
@export var player_audio_track_index: int = -1
@export var opponent_audio_track_index: int = -1
@export_file(".tscn") var scene_path: String


static func load_from_song(song: String, songs_folder: String) -> SongMetadata:
	var path := "%s/%s/meta.tres" % [songs_folder, song]
	if ResourceLoader.exists(path):
		return load(path)
	else:
		return null


func get_full_name() -> StringName:
	if mix != &"Default":
		return &"%s [%s Mix]" % [display_name, mix]
	else:
		return display_name
