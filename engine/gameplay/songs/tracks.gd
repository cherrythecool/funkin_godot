## A helper class that handles loading
## the audio tracks for a given in-game song.
class_name Tracks
extends Node


## Tries to find tracks of the specified song and path,
## returns true if they exist and false if they don't.
static func tracks_exist(song: StringName, path: String) -> bool:
	var song_folder := "%s/%s" % [path, song]
	var files := ResourceLoader.list_directory("%s/tracks" % song_folder)
	return not files.is_empty()


## Finds and loads the tracks for the given song and path.
##
## Will try to generate an AudioStreamSynchronized if a tracks folder
## can be found. (Loading all resources in the folder)
static func load_tracks(song: StringName, path: String) -> AudioStream:
	var song_folder := "%s/%s" % [path, song]
	var files := ResourceLoader.list_directory("%s/tracks" % [song_folder])
	if files.is_empty():
		return null

	var tracks := AudioStreamSynchronized.new()
	for file: String in files:
		if tracks.stream_count == AudioStreamSynchronized.MAX_STREAMS:
			printerr("Cannot load more than %d streams into one AudioStreamSynchronized!" % AudioStreamSynchronized.MAX_STREAMS)
			break

		var track_path := "%s/tracks/%s" % [song_folder, file]
		if not ResourceLoader.exists(track_path, "AudioStream"):
			continue

		tracks.stream_count += 1
		tracks.set_sync_stream(
			tracks.stream_count - 1,
			load(track_path)
		)

	return tracks
