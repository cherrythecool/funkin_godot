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
@export var type_data: Dictionary[StringName, Variant]

@export_group("Basic Type Info")
@export var should_hit: bool = true
@export var hit_health_multiplier: float = 1.0
@export var miss_health_multiplier: float = 1.0

@export var use_custom_score: bool = false
@export var custom_score: int = 0

var state: NoteState = NoteState.ALIVE
var grace_timer: float = 1.0
var strumline: StringName
