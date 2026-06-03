class_name VSliceChart
extends Object


# Do not need the `easeDir` fixes.
const IGNORED_EASINGS: PackedStringArray = [
	"linear",
	"classic",
	"instant",
]


static func is_vslice(song_folder: String, difficulty: StringName) -> bool:
	var metadata_path := "%s/charts/meta.json" % song_folder
	var metadata_exists := ResourceLoader.exists(metadata_path, "JSON")

	if not metadata_exists:
		metadata_path = "%s/charts/metadata.json" % song_folder
		metadata_exists = ResourceLoader.exists(metadata_path, "JSON")

	if not metadata_exists:
		return false

	var chart_path := "%s/charts/chart.json" % song_folder
	var chart_exists := ResourceLoader.exists(chart_path, "JSON")

	if not chart_exists:
		return false

	var data: Variant = load(chart_path).data
	if data is not Dictionary:
		return false

	return data.get("notes", {}).has(String(difficulty))


static func load_vslice(song_folder: String, difficulty: StringName) -> Chart:
	var chart := Chart.new()

	var metadata_path := "%s/charts/meta.json" % song_folder
	if not ResourceLoader.exists(metadata_path, "JSON"):
		metadata_path = "%s/charts/metadata.json" % song_folder

	var metadata: Variant = load(metadata_path).data
	for change_data: Dictionary in metadata.get("timeChanges", []):
		var change := TimingChange.new()
		change.time = maxf(change_data.get("t") / 1000.0, 0.0)
		change.bpm_changed = true
		change.bpm = float(change_data.get("bpm", 0.0))
		chart.timing_changes.push_back(change)

	var chart_path: String = "%s/charts/chart.json" % song_folder
	var data: Variant = load(chart_path).data

	var difficulty_string := String(difficulty).to_lower()
	if "scrollSpeed" in data:
		if data["scrollSpeed"] is float:
			chart.scroll_speed = data["scrollSpeed"]
		elif data["scrollSpeed"] is Dictionary:
			if data["scrollSpeed"].has(difficulty_string):
				chart.scroll_speed = data["scrollSpeed"].get(difficulty_string)
			else:
				chart.scroll_speed = data["scrollSpeed"].get("default", 1.0)

	if data.has("events"):
		for event: Dictionary in data["events"]:
			if event.get("e") == "FocusCamera":
				chart.events.push_back(_parse_focus_camera(event))
			else:
				chart.events.push_back(
					DynamicEvent.new(
						event.get("e"),
						float(event.get("t") / 1000.0),
						event.get("v"),
					)
				)

	chart.generate_default_events()
	chart.snap_starting_events()

	for note: Dictionary in data.notes.get(difficulty):
		var note_data := NoteData.new()
		note_data.time = note.get("t") / 1000.0
		note_data.beat = Conductor.get_beat_at_time(note_data.time, chart.timing_changes)

		if note.has("l"):
			note_data.length = note.get("l") / 1000.0

		var direction: int = note.get("d")
		var side: StringName = &"player" if direction < 4 else &"opponent"
		note_data.direction = direction % 4

		note_data.type = note.get("k", &"default")
		chart.update_note_types(side, note_data.type)

		chart.strumlines[side][&"notes"].push_back(note_data)

	chart.sort()

	var stacked_notes: int = chart.remove_stacked_notes()
	print("Loaded FNFCChart(%s) with %s stacked notes detected." % [
		"%s (%s)" % [metadata.get("songName", "Unknown"), difficulty],
		stacked_notes,
	])

	return chart


static func _get_side_from_camera_event(value: int) -> StringName:
	match value:
		0:
			return &"player"
		1:
			return &"opponent"
		2:
			return &"spectator"
		_:
			return &"player"


static func _parse_focus_camera(event: Dictionary) -> CameraPan:
	if event.get("v") is Dictionary:
		var values: Dictionary = event.get("v", {})
		var ease_string: String = values.get("ease", "CLASSIC")
		if values.has("easeDir") and ease_string.to_lower() not in IGNORED_EASINGS:
			ease_string += values.get("easeDir")

		return CameraPan.new(
			float(event.get("t") / 1000.0),
			_get_side_from_camera_event(int(values.get("char", 0))),
			ease_string,
			float(values.get("duration", 32.0)),
			Vector2(
				float(values.get("x", 0.0)),
				float(values.get("y", 0.0)),
			)
		)
	else:
		return CameraPan.new(
			float(event.get("t") / 1000.0),
			_get_side_from_camera_event(int(event.get("v", 0))),
		)
