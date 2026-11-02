extends FunkinScript


func _on_note_prepare(note: NoteData, _strumline_key: StringName) -> void:
	if note.type != &"Alt Animation" or note.type != &"alt":
		return

	note.sing_suffix = &"_alt"
