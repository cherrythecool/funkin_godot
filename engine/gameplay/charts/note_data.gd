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
@export var custom_type_data: Dictionary[StringName, Variant] = {}

@export_group("Singing Type Info")
@export var sing_animations := true
@export var sing_prefix := &"sing_"
@export var sing_suffix := &""
@export var use_custom_sing := false
@export var custom_sing_anim := &""

@export var miss_animations := true
@export var miss_prefix := &"sing_"
@export var miss_suffix := &"_miss"
@export var use_custom_miss := false
@export var custom_miss_anim := &""

@export_group("Gameplay Type Info")
@export var should_hit: bool = true
@export var hit_health_multiplier: float = 1.0
@export var miss_health_multiplier: float = 1.0

@export var use_custom_score: bool = false
@export var custom_score: int = 0

var state: NoteState = NoteState.ALIVE
var grace_timer: float = 1.0
var strumline: StringName
