class_name NoteData
extends RefCounted


enum NoteState {
	ALIVE = 0,
	HELD,
	HIT,
	MISSED,
}


@export var time: float
@export var beat: float
@export var direction: int
@export var length: float

@export var type: StringName

var state: NoteState = NoteState.ALIVE
