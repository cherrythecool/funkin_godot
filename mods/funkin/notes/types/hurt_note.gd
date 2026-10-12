extends FunkinScript


func _on_note_prepare(note: NoteData) -> void:
	if note.type != &"Hurt Note":
		return

	note.should_hit = false
