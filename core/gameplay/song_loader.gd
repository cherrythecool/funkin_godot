class_name SongLoader
extends Node


static func get_scene_path(song: String, songs_folder: String) -> String:
	var meta := SongMetadata.load_from_song(song, songs_folder)
	if is_instance_valid(meta) and ResourceLoader.exists(meta.scene_path):
		return meta.scene_path
	else:
		return "uid://da8mu3oqto3qq"
