class_name ModchartEaseEvent extends ModchartEvent

var start_value: float

var end_step: float = 0

var target_trans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR
var target_ease: Tween.EaseType = Tween.EaseType.EASE_OUT

var _tween: Tween
func run() -> void:
	if start_value == null: start_value = _get_value()
	_tween = create_tween().set_trans(target_trans).set_ease(target_ease)
	_tween.tween_method(_set_value, start_value, value, Conductor.instance.step_delta * (end_step - start_step))

func kill() -> void:
	if _tween != null:
		await _tween.finished
	super()
