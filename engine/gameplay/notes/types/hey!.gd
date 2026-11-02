extends FunkinScript


func _on_note_prepare(note: NoteData, _strumline_key: StringName) -> void:
	if note.type != &"Hey!":
		return

	note.use_custom_sing = true
	note.custom_sing_anim = &"hey"
