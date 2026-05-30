@tool
class_name AlphabetSkin
extends Resource


@export var sprite_frames: SpriteFrames = null
@export var suffix: String = ""
@export var character_map: Dictionary[PackedStringArray, AlphabetSkinCharacter] = {}
@export var space_width: float = 34.0

var baked_map: bool = false
var optimized_map: Dictionary[String, AlphabetSkinCharacter] = {}


func bake_optimized_map() -> void:
	if baked_map:
		return

	optimized_map.clear()

	for key: PackedStringArray in character_map.keys():
		for value: String in key:
			optimized_map.set(value, character_map.get(key))

	baked_map = true
