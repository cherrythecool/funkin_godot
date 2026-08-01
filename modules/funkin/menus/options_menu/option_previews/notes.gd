extends Node2D


var lane: int = 0

@onready var manager: StrumlineManager = $manager
@onready var renderer: StrumlineRenderer2D = $renderer


func _ready() -> void:
	Settings.setting_changed.connect(_on_setting_changed)
	Conductor.instance.beat_hit.connect(_on_beat_hit)
	renderer.scroll_speed = Settings.get_setting(&"core", "note_scroll_value")


func _process(_delta: float) -> void:
	# Clean up notes when song restarts
	for note: NoteData in manager.notes:
		if note.time - Conductor.instance.time >= 4.0:
			lane = 0
			manager.clear_notes()
			break


func _on_beat_hit(beat: int) -> void:
	var note := NoteData.new()
	note.time = Conductor.instance.raw_time + (Conductor.instance.beat_delta * 4.0)
	note.beat = float(beat + 4.0)
	note.direction = lane
	note.length = 0.0
	note.type = &"default"
	manager.push_note(note)

	lane = wrapi(lane + 1, 0, 4)


func _on_setting_changed(file: StringName, key: Variant) -> void:
	if file == &"core" and key == "note_scroll_value":
		renderer.scroll_speed = Settings.get_setting(file, key, 0.0)
