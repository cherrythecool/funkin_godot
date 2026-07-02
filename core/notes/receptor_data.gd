class_name ReceptorData
extends Resource


@export var direction: StringName = &"left"
@export var framerate: float = 24.0

var animation: StringName:
	get:
		match animation_state:
			StrumlineManager.ReceptorState.HIT:
				return &"confirm"
			StrumlineManager.ReceptorState.PRESSED:
				return &"press"
			StrumlineManager.ReceptorState.RELEASED, _:
				return &"static"

var animation_state: StrumlineManager.ReceptorState = StrumlineManager.ReceptorState.RELEASED
var animation_progress: float = 0.0

var animation_frame: int:
	get:
		return floori(animation_progress * framerate)

var hold_timer: float = 0.0
