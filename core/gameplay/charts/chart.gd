class_name Chart
extends RefCounted


var strumlines: Dictionary[StringName, Dictionary] = {}
var events: Array[EventData] = []
var timing_changes: Array[TimingChange] = []
var scroll_speed: float = 1.0


static func sort_by_time(a: Variant, b: Variant) -> bool:
	return a.time < b.time


static func new_strumline() -> Dictionary:
	return {
		&"notes": [],
		&"note_types": [],
		&"override_scroll_speed": false,
		&"scroll_speed": 1.0,
	}


static func load_chart(song_folder: String, difficulty: StringName) -> Chart:
	difficulty = difficulty.to_lower()

	if LegacyFunkinChart.is_legacy(song_folder, difficulty):
		return LegacyFunkinChart.load_legacy(song_folder, difficulty)
	else:
		return failed_load(song_folder, difficulty)


static func failed_load(song_folder: String, difficulty: StringName) -> Chart:
	printerr("Song %s with difficulty %s could not be found" % [song_folder, difficulty])
	return null


#static func try_legacy(base_path: String, difficulty: StringName) -> Chart:
	#var legacy_exists: bool = ResourceLoader.exists('%s/charts/%s.json' % [base_path, difficulty])
	#if not legacy_exists:
		#return null
#
	#var path: String = '%s/charts/%s.json' % [base_path, difficulty]
	#var funkin: FunkinLegacyChart = FunkinLegacyChart.new()
	#funkin.json = load(path).data
	#if 'codenameChart' in funkin.json and funkin.json.codenameChart == true:
		#return CodenameChart.parse(base_path, funkin.json)
#
	#if funkin.json.song is Dictionary:
		#funkin.scroll_speed = funkin.json.song.get('speed', 1.0)
	#else:
		#funkin.scroll_speed = funkin.json.get('speed', 1.0)
#
	#var extra_events: Array[EventData] = []
	#var events_path: String = '%s/charts/events.json' % [base_path]
	#if ResourceLoader.exists(events_path):
		#var events_json: String = FileAccess.get_file_as_string(events_path)
		#var data: Dictionary = JSON.parse_string(events_json)
		#if data.song is Dictionary:
			#extra_events.append_array(FunkinLegacyChart.parse_events(data.song))
		#else:
			#extra_events.append_array(FunkinLegacyChart.parse_events(data))
#
	#var chart: Chart = funkin.parse()
	#chart.events.append_array(extra_events)
	#chart.events.sort_custom(sort_time_based)
	#return chart


#static func try_fnfc(base_path: String, difficulty: StringName) -> Chart:
	#var fnfc_exists: bool = ResourceLoader.exists('%s/charts/chart.json' % [base_path]) and \
			#(ResourceLoader.exists('%s/charts/meta.json' % [base_path]) or ResourceLoader.exists('%s/charts/metadata.json' % [base_path]))
	#if not fnfc_exists:
		#return null
#
	#var fnfc: FNFCChart = FNFCChart.new()
	#var chart_path: String = '%s/charts/chart.json' % [base_path]
	#fnfc.json_chart = load(chart_path).data
#
	#var meta_path: String = '%s/charts/meta.json' % [base_path]
	#if not ResourceLoader.exists(meta_path):
		#meta_path = '%s/charts/metadata.json' % [base_path]
	#var meta_data: String = FileAccess.get_file_as_string(meta_path)
	#fnfc.json_meta = JSON.parse_string(meta_data)
#
	#if "scrollSpeed" in fnfc.json_chart:
		#if fnfc.json_chart.scrollSpeed is float:
			#fnfc.scroll_speed = fnfc.json_chart.scrollSpeed
		#else:
			#if fnfc.json_chart.scrollSpeed.has(difficulty.to_lower()):
				#fnfc.scroll_speed = fnfc.json_chart.scrollSpeed.get(difficulty.to_lower(), 1.0)
			#else:
				#fnfc.scroll_speed = fnfc.json_chart.scrollSpeed.get('default', 1.0)
#
	#return fnfc.parse(difficulty)


func sort() -> void:
	for key: StringName in strumlines:
		var strumline: Dictionary = strumlines[key]
		strumline[&"notes"].sort_custom(sort_by_time)

	timing_changes.sort_custom(sort_by_time)
	events.sort_custom(sort_by_time)


func remove_stacked_notes(min_time: float = 0.005) -> int:
	var total_stacked: int = 0

	for key: StringName in strumlines:
		var strumline: Dictionary = strumlines[key]
		var notes: Array = strumline[&"notes"]
		var last_times: Dictionary[int, float] = {}

		var index: int = 0
		while index < notes.size() and not notes.is_empty():
			var note: NoteData = notes[index]
			if not last_times.has(note.direction):
				last_times[note.direction] = note.time
				index += 1
				continue

			if absf(note.time - last_times[note.direction]) <= min_time:
				notes.remove_at(index)
				total_stacked += 1
				continue

			last_times[note.direction] = note.time
			index += 1

	return total_stacked
