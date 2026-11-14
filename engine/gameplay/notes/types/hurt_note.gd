extends FunkinScript


func _on_note_prepare(note: NoteData, _strumline_key: StringName) -> void:
	if note.type != &"Hurt Note":
		return

	note.should_hit = false
	note.sing_suffix = &"_miss"
	note.hit_window_multiplier *= 0.3
	note.miss_health_multiplier *= 5.0


func _on_note_spawned(note: Note2D, _strumline_key: StringName) -> void:
	if note.data.type != &"Hurt Note":
		return

	note.modulate = Color(0.1, 0.0, 0.0)
