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

@export var strumline: StringName = &"player"
@export var hit_window: float = 0.18
@export var cpu: bool = true
@export var conductor: Conductor

var rating_manager: RatingManager
var receptor_states: Array[ReceptorState]
var notes: Array[NoteData]
var notes_index: int = 0


func _ready() -> void:
	rating_manager = get_tree().get_first_node_in_group(&"RatingManager")
	receptor_states.resize(4)
	receptor_states.fill(ReceptorState.RELEASED)


func _process(delta: float) -> void:
	if cpu:
		receptor_states.fill(ReceptorState.RELEASED)

	var time := get_time()
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
				var past_hit_window := (
					time > note.time + hit_window and
					note.state == NoteData.NoteState.ALIVE
				)
				var sustain_missed := (
					(note.grace_timer <= 0.0 and note.length > 0.0) and
					note.state == NoteData.NoteState.HELD
				)
				var should_miss := past_hit_window or sustain_missed

				if should_miss:
					miss_note(note)
					shift_notes_index = note_idx == 0
				elif time >= note.time + note.length and note.state == NoteData.NoteState.HELD:
					hit_note(note)
					shift_notes_index = note_idx == 0

		if shift_notes_index:
			notes_index += 1
		else:
			note_idx += 1

	if not cpu:
		_handle_player_input(delta)


func hit_note(note: NoteData) -> void:
	var time := get_time()
	if rating_manager and note.state == NoteData.NoteState.ALIVE and not cpu:
		rating_manager.add_note_hit(0.0 if cpu else absf(time - note.time))

	note_hit.emit(note)

	if time < note.time + note.length and note.length > 0.0:
		note.state = NoteData.NoteState.HELD
	else:
		note.state = NoteData.NoteState.HIT

	note.grace_timer = Conductor.sustain_release_delta
	receptor_states[note.direction] = ReceptorState.HIT


func miss_note(note: NoteData) -> void:
	if rating_manager and not cpu:
		rating_manager.add_note_miss()

	note_missed.emit(note)
	note.state = NoteData.NoteState.MISSED


func is_note_in_range(note: NoteData, time: float) -> bool:
	return time >= note.time - hit_window


func get_time() -> float:
	if conductor:
		return conductor.time
	else:
		return Conductor.time


func load_notes(notes_array: Array) -> void:
	notes.append_array(notes_array)

	for note: NoteData in notes_array:
		note.state = NoteData.NoteState.ALIVE
		note.strumline = strumline


func push_note(note: NoteData) -> void:
	if notes.is_empty():
		notes.push_back(note)
	else:
		var sort := notes[notes.size() - 1].time > note.time
		notes.push_back(note)

		if sort:
			notes_index = 0
			notes.sort_custom(Chart.sort_by_time)


func clear_notes() -> void:
	notes.clear()
	notes_index = 0


func skip_missed_notes(time_range: float) -> void:
	var time := get_time()
	while notes_index < notes.size():
		var note := notes[notes_index]
		if time + time_range > note.time:
			notes_index += 1
		else:
			return


func _handle_player_input(delta: float) -> void:
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

	var time := get_time()
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
				else:
					note.grace_timer -= delta

				held[note.direction] = false
				if note.grace_timer <= 0.0:
					miss_note(note)
