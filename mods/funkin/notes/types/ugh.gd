extends FunkinScript


func _on_note_prepare(note: NoteData) -> void:
	if note.type != &"ugh":
		return

	note.use_custom_sing = true
	note.custom_sing_anim = &"ugh"
