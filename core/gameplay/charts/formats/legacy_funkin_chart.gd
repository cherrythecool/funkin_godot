class_name LegacyFunkinChart
extends Object


var json: Dictionary
var scroll_speed: float = 1.0


static func is_legacy(song_folder: String, difficulty: StringName) -> bool:
	var path := "%s/charts/%s.json" % [song_folder, difficulty]
	var chart_exists := ResourceLoader.exists(path, "JSON")

	if not chart_exists:
		return false

	var data: Variant = load(path).data
	if data is not Dictionary:
		return false

	if data.get("codenameChart", false) == true:
		return false
	else:
		return true


static func load_legacy(song_folder: String, difficulty: StringName) -> Chart:
	var path := "%s/charts/%s.json" % [song_folder, difficulty]
	var data: Dictionary = load(path).data as Dictionary
	if not data.has("song"):
		printerr("Legacy Funkin Chart is missing song property, refusing to load.")
		return

	var song_data: Dictionary

	var chart := Chart.new()
	chart.scroll_speed = song_data.get("speed", 1.0)

	# Only format I know that does this is Psych 1.0, so that's why the check
	# for this is how it is.
	var notes_use_must_hit: bool = true
	if data["song"] is Dictionary:
		song_data = data["song"]
	else:
		song_data = data
		notes_use_must_hit = false

	var sections: Array = song_data["notes"]
	var bpm: float = song_data["bpm"]
	var beat: float = 0.0
	var time: float = 0.0

	if song_data.has("events"):
		chart.events.append_array(load_psych_events(song_data["events"]))

	if sections.is_empty():
		return

	var must_hit: bool = sections[0].mustHitSection
	chart.events.push_back(CameraPan.new(time, &"player" if must_hit else &"opponent"))

	chart.strumlines[&"player"] = Chart.new_strumline()
	chart.strumlines[&"opponent"] = Chart.new_strumline()
	chart.strumlines[&"spectator"] = Chart.new_strumline()

	for section: Dictionary in sections:
		if section.get("changeBPM", false) and section.get("bpm", 0.0) != bpm:
			bpm = section.get("bpm", 0.0)

			var change := TimingChange.new()
			change.bpm_changed = true
			change.bpm = bpm
			chart.timing_changes.push_back(change)

		if section.mustHitSection != must_hit:
			must_hit = section.mustHitSection
			chart.events.push_back(CameraPan.new(time, &"player" if must_hit else &"opponent"))

		var section_length: float = section.get("sectionBeats", 4.0)
		var beat_delta: float = 60.0 / bpm
		for note: Array in section.sectionNotes:
			if int(note[1]) < 0:
				continue

			var note_data := NoteData.new()
			note_data.time = float(note[0]) / 1000.0
			note_data.beat = beat + ((note_data.time - time) * beat_delta)
			note_data.length = maxf(float(note[2]) / 1000.0, 0.0)

			var direction := int(note[1])
			note_data.direction = absi(direction) % 4

			var side: StringName
			if notes_use_must_hit:
				if must_hit:
					side = &"player" if direction < 4 else &"opponent"
				else:
					side = &"opponent" if direction < 4 else &"player"
			else:
				side = &"opponent" if direction < 4 else &"player"

			if note.size() > 3 and note[3] is String:
				note_data.type = StringName(note[3])
			else:
				note_data.type = &"default"

			var strumline: Dictionary = chart.strumlines[side]
			if note_data.type not in strumline[&"note_types"]:
				strumline[&"note_types"].push_back(note_data.type)

			strumline[&"notes"].push_back(note_data)

		beat += section_length
		time += section_length * beat_delta

	chart.sort()

	var stacked_note_count: int = chart.remove_stacked_notes()
	print("Loaded LegacyFunkinChart(%s) with %s stacked notes detected." % [
		song_data["song"],
		stacked_note_count,
	])

	return chart


static func load_psych_events(raw_events: Array) -> Array[EventData]:
	var events: Array[EventData] = []
	if raw_events.is_empty():
		return events

	for object: Array in raw_events:
		if object[0] is not float:
			continue

		var event_time: float = object[0] / 1000.0
		for event: Array in object[1]:
			var event_name: String = event[0]
			var params: Array[String] = [event[1], event[2]]
			events.push_back(DynamicEvent.new(event_name, event_time, params))

	return events
