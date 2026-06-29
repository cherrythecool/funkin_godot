class_name StrumlineManager
extends Node


signal note_hit(note: NoteData)
signal note_missed(note: NoteData)

enum ReceptorState {
	RELEASED = 0,
	HIT,
	PRESSED,
}

const INPUT_ACTIONS: PackedStringArray = ["note_left", "note_down", "note_up", "note_right"]

@export var hit_window: float = 0.18
@export var cpu: bool = true

var receptor_states: Array[ReceptorState]
var notes: Array[NoteData]
var notes_index: int = 0


func _ready() -> void:
	receptor_states.resize(4)
	receptor_states.fill(ReceptorState.RELEASED)


func _process(_delta: float) -> void:
	if cpu:
		receptor_states.fill(ReceptorState.RELEASED)

	var time := Conductor.time
	var note_idx := 0

	while notes_index + note_idx < notes.size():
		var note := notes[notes_index + note_idx]
		if not is_note_in_range(note, time):
			break

		var shift_notes_index := false
		var finished := note.state == NoteData.NoteState.HIT or note.state == NoteData.NoteState.MISSED
		if finished:
			shift_notes_index = note_idx == 0
		else:
			if cpu:
				if time >= note.time:
					hit_note(note)
					shift_notes_index = note_idx == 0 and note.state == NoteData.NoteState.HIT
			else:
				if time > note.time + hit_window and note.state == NoteData.NoteState.ALIVE:
					miss_note(note)
					shift_notes_index = note_idx == 0

		if shift_notes_index:
			notes_index += 1
		else:
			note_idx += 1

	if not cpu:
		_handle_player_input()


func _handle_player_input() -> void:
	var pressed: Array[bool]
	pressed.resize(INPUT_ACTIONS.size())

	var held: Array[bool]
	held.resize(INPUT_ACTIONS.size())

	for i: int in INPUT_ACTIONS.size():
		var action := StringName(INPUT_ACTIONS[i])
		pressed[i] = Input.is_action_just_pressed(action)
		held[i] = Input.is_action_pressed(action)

		if not held[i]:
			receptor_states[i] = ReceptorState.RELEASED
		elif pressed[i] and receptor_states[i] == ReceptorState.RELEASED:
			receptor_states[i] = ReceptorState.PRESSED

	if true not in held:
		return

	var time := Conductor.time
	for index: int in range(notes_index, notes.size()):
		var note := notes[index]
		if not is_note_in_range(note, time):
			break

		match note.state:
			NoteData.NoteState.ALIVE:
				if not pressed[note.direction]:
					continue

				pressed[note.direction] = false
				hit_note(note)
			NoteData.NoteState.HELD:
				if held[note.direction]:
					hit_note(note)


func hit_note(note: NoteData) -> void:
	var time := Conductor.time

	if time < note.time + note.length and note.length > 0.0:
		note.state = NoteData.NoteState.HELD
	else:
		note.state = NoteData.NoteState.HIT

	receptor_states[note.direction] = ReceptorState.HIT
	note_hit.emit(note)


func miss_note(note: NoteData) -> void:
	note.state = NoteData.NoteState.MISSED
	note_missed.emit(note)


func is_note_in_range(note: NoteData, time: float) -> bool:
	return time >= note.time - hit_window


func load_notes(notes_array: Array) -> void:
	notes.append_array(notes_array)

	for note: NoteData in notes_array:
		note.state = NoteData.NoteState.ALIVE
