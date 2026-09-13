class_name Strumline
extends RefCounted


var notes: Array[NoteData] = []
var note_types: Array[StringName] = []

var key_count: int = 4
var override_scroll_speed := false
var scroll_speed := 1.0


func sort_notes() -> void:
	notes.sort_custom(Chart.sort_by_time)


func add_note(note: NoteData) -> void:
	notes.push_back(note)
	update_note_types(note.type)


func update_note_types(type: StringName) -> bool:
	if type not in note_types:
		note_types.push_back(type)
		return true
	else:
		return false
