class_name SongMetadata
extends Resource


@export_group("Display Info")
@export var display_name: StringName = &"Song Name"
@export var mix: StringName = &"Default"
@export var icon: HealthIcon = null

@export_group("Difficulties")
@export var difficulties: PackedStringArray = [
	"easy", "normal", "hard",
]
@export var difficulty_song_overrides: Dictionary[String, StringName] = {}

@export_group("Game Metadata")
@export var skip_countdown: bool = false
@export_file("*.tscn") var scene_path: String


static func load_from_song(song: String, songs_folder: String) -> SongMetadata:
	var path := "%s/%s/meta.tres" % [songs_folder, song]
	if ResourceLoader.exists(path):
		return load(path)
	else:
		var meta := SongMetadata.new()
		meta.display_name = song.to_pascal_case()
		return meta


func get_full_name() -> StringName:
	if mix != &"Default":
		return &"%s (%s Mix)" % [display_name, mix]
	else:
		return display_name


func get_override_name(default: StringName, difficulty: StringName = &"") -> StringName:
	if difficulty not in difficulty_song_overrides:
		return default
	else:
		return difficulty_song_overrides[difficulty]
