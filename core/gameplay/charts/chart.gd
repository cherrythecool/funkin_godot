class_name Chart
extends RefCounted


var strumlines: Dictionary[StringName, Dictionary] = {}
var events: Array[EventData] = []
var timing_changes: Array[TimingChange] = []
var scroll_speed: float = 1.0


static func sort_by_time(a: Variant, b: Variant) -> bool:
	return a.time < b.time


static func sort_events(a: EventData, b: EventData) -> bool:
	if (
		is_equal_approx(a.time, 0.0) and
		is_equal_approx(a.time, b.time) and
		a.trigger_before_countdown != b.trigger_before_countdown
	):
		return a.trigger_before_countdown
	else:
		return sort_by_time(a, b)


static func new_strumline() -> Dictionary:
	return {
		&"notes": [],
		&"note_types": [],
		&"override_scroll_speed": false,
		&"scroll_speed": 1.0,
	}


static func load_chart(song_folder: String, difficulty: StringName) -> Chart:
	difficulty = difficulty.to_lower()

	if VSliceChart.is_vslice(song_folder, difficulty):
		return VSliceChart.load_vslice(song_folder, difficulty)
	elif LegacyFunkinChart.is_legacy(song_folder, difficulty):
		return LegacyFunkinChart.load_legacy(song_folder, difficulty)
	elif CodenameChart.is_codename(song_folder, difficulty):
		return CodenameChart.load_codename(song_folder, difficulty)
	else:
		return failed_load(song_folder, difficulty)


static func failed_load(song_folder: String, difficulty: StringName) -> Chart:
	printerr("Song %s with difficulty %s could not be found" % [song_folder, difficulty])
	return null


func _init() -> void:
	strumlines[&"player"] = Chart.new_strumline()
	strumlines[&"opponent"] = Chart.new_strumline()
	strumlines[&"spectator"] = Chart.new_strumline()


func sort() -> void:
	for key: StringName in strumlines:
		var strumline: Dictionary = strumlines[key]
		strumline[&"notes"].sort_custom(sort_by_time)

	timing_changes.sort_custom(sort_by_time)
	events.sort_custom(sort_events)


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


func generate_default_events() -> void:
	var found_camera_pan: bool = false
	for event: EventData in events:
		if event is CameraPan and event.time <= 0.001:
			found_camera_pan = true
			break

	if not found_camera_pan:
		events.push_front(CameraPan.new())


func snap_starting_events() -> void:
	for event: EventData in events:
		if event.time <= 0.001 and event.trigger_before_countdown:
			event.time = 0.0


func update_note_types(strumline_key: StringName, type: StringName) -> bool:
	var strumline: Dictionary = strumlines[strumline_key]

	if type not in strumline[&"note_types"]:
		strumline[&"note_types"].push_back(type)
		return true
	else:
		return false
