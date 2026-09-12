class_name CodenameChart
extends RefCounted


static func is_codename(song_folder: String, difficulty: StringName) -> bool:
	var metadata_path := "%s/charts/meta.json" % song_folder
	if not ResourceLoader.exists(metadata_path, "JSON"):
		return false

	var chart_path := "%s/charts/%s.json" % [song_folder, difficulty.to_lower()]
	return ResourceLoader.exists(chart_path, "JSON")


static func load_codename(song_folder: String, difficulty: StringName) -> Chart:
	var chart := Chart.new()

	var metadata_path: String = "%s/charts/meta.json" % song_folder
	var metadata: Dictionary = load(metadata_path).data

	var chart_path := "%s/charts/%s.json" % [song_folder, difficulty.to_lower()]
	var data: Variant = load(chart_path).data
	if data is not Dictionary:
		printerr("Codename Chart needs to be a dictionary")
		return chart

	chart.scroll_speed = data.get("scrollSpeed", 1.0)

	var initial_change := TimingChange.new()
	initial_change.bpm_changed = true
	initial_change.bpm = metadata.get("bpm", 0.0)
	chart.timing_changes.push_back(initial_change)
	chart.events.push_back(CameraPan.new(0.0, &"opponent"))

	var note_types: Array = data.get("noteTypes", [])

	var sides: Array[StringName] = []
	var strumlines: Array = data.strumLines
	for strumline: Dictionary in strumlines:
		var type: int = strumline.get("type", 2)
		var is_first: bool

		match type:
			1:
				is_first = not &"player" in sides
				sides.append(&"player")
			2:
				is_first = not &"spectator" in sides
				sides.append(&"spectator")
			0, _:
				is_first = not &"opponent" in sides
				sides.append(&"opponent")

		var side: StringName
		if is_first:
			side = sides[sides.size() - 1]
		else:
			var character: String = "unknown"
			var characters: Array = strumline.get("characters", [])
			if (not characters.is_empty()) and characters[0] is String:
				character = characters[0]

			side = &"%d_%s" % [sides.size() - 1, character]
			chart.strumlines[side] = Chart.new_strumline()

		var notes: Array = strumline.notes
		for note: Dictionary in notes:
			var note_data: NoteData = NoteData.new()
			note_data.time = float(note.time) / 1000.0
			note_data.beat = Conductor.get_beat_at_time(note_data.time, chart.timing_changes)
			note_data.direction = int(note.id)

			note_data.length = clampf(float(note.sLen) / 1000.0, 0.0, INF)
			if note.type != 0:
				note_data.type = note_types[note.type - 1]
			else:
				note_data.type = &"default"

			note_data.strumline = side
			chart.strumlines[side][&"notes"].push_back(note_data)

	chart.sort()

	var stacked_notes: int = chart.remove_stacked_notes()
	print("Loaded CodenameChart(%s) with %s stacked notes detected." % [
		metadata.get("displayName", metadata.get("name", "Unknown Name")), stacked_notes
	])

	var events_path: String = "%s/charts/events.json" % song_folder
	if ResourceLoader.exists(events_path):
		var events: Dictionary = load(events_path).data
		parse_events(chart, events.get("events", []), sides)

	parse_events(chart, data.get("events", []), sides)
	return chart


static func parse_events(chart: Chart, events: Array, sides: Array[StringName]) -> void:
	for event: Dictionary in events:
		var name: String = event.name
		var params: Array = event.params
		var time: float = event.time / 1000.0

		match name:
			"Camera Movement":
				var ease_string: String = "CLASSIC"

				if params.size() >= 2 and not params[1]:
					ease_string = "INSTANT"
				elif params.size() >= 5 and params[3] != "CLASSIC":
					ease_string = str(params[3]) + str(params[4])

				chart.events.append(
					CameraPan.new(
						time,
						sides[params[0]],
						ease_string,
						32.0 if params.size() < 3 else params[2],
					)
				)
			"Camera Zoom":
				if str(params[2]) != "camGame":
					continue

				chart.events.append(DynamicEvent.new(&"ZoomCamera", time, {
					"duration": float(params[3]),
					"ease": str(params[4]) + str(params[5]) if params[0] else "INSTANT",
					"mode": str(params[6]),
					"zoom": float(params[1])
				}))
			"BPM Change":
				var change := TimingChange.new()
				change.time = time
				change.bpm_changed = true
				change.bpm = params[0]
				chart.timing_changes.append(change)
			_:
				chart.events.append(DynamicEvent.new(name, time, params))
