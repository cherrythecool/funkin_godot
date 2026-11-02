extends Character


func _on_beat_hit(beat: int) -> void:
	super(beat)


func play_anim(anim: StringName, force: bool = false, special: bool = false) -> void:
	super(anim, force, special)


func _on_note_hit(note: NoteData) -> void:
	super(note)


func _on_note_missed(note: NoteData) -> void:
	super(note)


func dance(force: bool = false) -> void:
	super(force)


func set_character_material(new_material: Material) -> void:
	super(new_material)

	# Use for custom logic if you have more sprites than just the one default (or setup scene with use_parent_material in mind)
