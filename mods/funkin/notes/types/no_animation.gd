extends FunkinScript


func _on_note_prepare(note: NoteData) -> void:
	if note.type != &"No Animation":
		return

	note.sing_animations = false
	note.miss_animations = false
