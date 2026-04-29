extends Node2D


@onready var notes: NoteField = $notes

var lane: int = 0


func _ready() -> void:
	Settings.setting_changed.connect(_on_setting_changed)
	Conductor.instance.beat_hit.connect(_on_beat_hit)
	notes.scroll_speed = Settings.get_setting(&"core", "note_scroll_value")


func _process(_delta: float) -> void:
	# clean up notes when song restarts
	for note: Note in notes.notes:
		if note.data.time - Conductor.instance.time >= 4.0:
			notes.remove_note(note)


func _on_beat_hit(beat: int) -> void:
	var data: NoteData = NoteData.new()
	data.time = Conductor.instance.raw_time + (Conductor.instance.beat_delta * 4.0)
	data.beat = float(beat + 4.0)
	data.direction = lane
	data.length = 0.0
	data.type = &"default"
	notes.spawn_note(data)
	lane = wrapi(lane + 1, 0, 4)


func _on_setting_changed(file: StringName, key: Variant) -> void:
	if file == &"core" and key == "note_scroll_value":
		notes.scroll_speed = Settings.get_setting(file, key, 0.0)
