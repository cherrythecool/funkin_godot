class_name ReceptorData
extends Resource


@export var direction: StringName = &"left":
	set(v):
		if direction != v:
			direction = v
			animation_name = &"%s %s" % [direction, animation]

var animation: StringName:
	get:
		match animation_state:
			StrumlineManager.ReceptorState.HIT:
				return &"confirm"
			StrumlineManager.ReceptorState.PRESSED:
				return &"press"
			StrumlineManager.ReceptorState.RELEASED, _:
				return &"static"

var animation_state: StrumlineManager.ReceptorState = StrumlineManager.ReceptorState.RELEASED:
	set(v):
		if animation_state != v:
			animation_state = v
			animation_name = &"%s %s" % [direction, animation]

var animation_progress: float = 0.0
var animation_name: StringName

var hold_timer: float = 0.0

var splash_progress: float = 0.0
var splash_animation: StringName


func _init() -> void:
	animation_name = &"%s %s" % [direction, animation]
