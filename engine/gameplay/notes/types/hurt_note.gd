extends FunkinScript


func _on_note_prepare(note: NoteData, _strumline_key: StringName) -> void:
	if note.type != &"Hurt Note":
		return

	note.should_hit = false
