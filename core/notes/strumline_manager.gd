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
	var counter := 0

	while notes_index + counter < notes.size():
		var note := notes[notes_index + counter]
		if time < note.time - hit_window:
			break

		if note.state != NoteData.NoteState.ALIVE:
			if counter == 0:
				notes_index += 1

			counter += 1
			continue

		if time >= note.time and cpu:
			hit_note(note)

			if counter == 0 and note.length <= 0.0:
				notes_index += 1
			else:
				counter += 1

			continue

		if time > note.time + hit_window and not cpu:
			note.state = NoteData.NoteState.MISSED
			note_missed.emit(note)

			if counter == 0:
				notes_index += 1

			continue

		counter += 1


func _input(event: InputEvent) -> void:
	if cpu or event.is_echo():
		return
	for action: String in INPUT_ACTIONS:
		if event.is_action(StringName(action)):
			_handle_player_input()
			break


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
		if time < note.time - hit_window:
			break

		match note.state:
			NoteData.NoteState.ALIVE:
				if not pressed[note.direction]:
					continue

				pressed[note.direction] = false
				hit_note(note)
			_:
				continue


func hit_note(note: NoteData) -> void:
	note.state = NoteData.NoteState.HIT
	receptor_states[note.direction] = ReceptorState.HIT
	note_hit.emit(note)


func load_notes(notes_array: Array) -> void:
	notes.append_array(notes_array)

	for note: NoteData in notes_array:
		note.state = NoteData.NoteState.ALIVE
