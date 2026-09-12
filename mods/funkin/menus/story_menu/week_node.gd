extends TextureRect
class_name StoryWeekNode


@export var songs: PackedStringArray
@export var difficulties: PackedStringArray

@export_group("Visuals")
@export var display_name: StringName
@export var background_color: Color = Color("#f9cf51")
@export var props: StoryWeekProps

@export_group("Advanced")
@export var difficulty_suffixes: Dictionary[StringName, StringName] = {}


func get_song_name(index: int, difficulty: StringName) -> StringName:
	return songs[index] + difficulty_suffixes.get(difficulty, &"")
