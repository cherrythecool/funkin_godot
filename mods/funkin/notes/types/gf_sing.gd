extends FunkinScript


func _on_note_prepare(note: NoteData) -> void:
	if note.type != &"GF Sing":
		return

	note.sing_animations = false
	note.miss_animations = false


func _on_note_hit(note: NoteData, _strumline_key: StringName) -> void:
	if note.type != &"GF Sing":
		return

	note.sing_animations = true
	spectator._on_note_hit(note)
	note.sing_animations = false


func _on_note_missed(note: NoteData, _strumline_key: StringName) -> void:
	if note.type != &"GF Sing":
		return

	note.miss_animations = true
	spectator._on_note_missed(note)
	note.miss_animations = false
