class_name ModchartEaseEvent extends ModchartSetEvent

var end_step: int = 0
var start_value: Variant = null

var target_trans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR
var target_ease: Tween.EaseType = Tween.EaseType.EASE_OUT

func run(step: float) -> void:
	if start_value == null: start_value = _get_value()
	var length: float = end_step - exec_step
	
	if step >= end_step:
		finished = true
		_set_value(value)
		return
	
	var progress: float = (step - exec_step) / length
	var change: float = value - start_value
	
	_set_value(Tween.interpolate_value(start_value, change, progress, 1, target_trans, target_ease))


func _get_value() -> float:
	if sub_modifier != null && !sub_modifier.is_empty():
		return modchart_manager.get_submod_value(modifier, sub_modifier, player)
	else:
		return modchart_manager.get_value(modifier, player)

func _set_value(_value:float) -> void:
	if sub_modifier != null && !sub_modifier.is_empty():
		modchart_manager.set_submod_value(modifier, sub_modifier, _value, player)
	else:
		modchart_manager.set_value(modifier, _value, player)
