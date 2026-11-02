extends FunkinScript


func _on_note_prepare(note: NoteData, strumline_key: StringName) -> void:
	if note.type != &"Note Type Name":
		return

	# You can modify anything directly about NoteData here.
	note.sing_suffix = &"_something"

	# Maybe do something special per strumline too, I'm not your boss.
	if strumline_key == &"opponent":
		note.should_hit = false


func _on_note_spawned(note: Note2D, strumline_key: StringName) -> void:
	if note.data.type != &"Note Type Name":
		return

	# You can modify anything about a visible Note2D here.
	# (Only applicable if using a HUD that has either player_renderer or opponent_renderer
	# as variables which are also of type Strumline2D. Otherwise you must bind this
	# function yourself)
	note.modulate = Color.RED

	# Maybe do something special per strumline too, I'm not your boss.
	if strumline_key == &"opponent":
		note.scale *= Vector2(1.2, 0.8)
