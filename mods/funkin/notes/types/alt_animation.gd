extends FunkinScript


func _on_note_prepare(note: NoteData) -> void:
	if note.type != &"Alt Animation" or note.type != &"alt":
		return

	note.sing_suffix = &"_alt"
