class_name ModchartEaseEvent extends ModchartSetEvent

var end_step: int = 0
var start_value: Variant = null

var target_trans: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR
var target_ease: Tween.EaseType = Tween.EaseType.EASE_OUT

func run(step: float) -> void:
	if start_value == null: start_value = modchart_manager.get_value(modifier, player)
	var length: float = end_step - exec_step
	
	if step >= end_step:
		finished = true
		modchart_manager.set_value(modifier, value, player)
		return
	
	var progress: float = (step - exec_step) / length
	var change: float = value - start_value
	
	modchart_manager.set_value(modifier, Tween.interpolate_value(start_value, change, progress, 1, target_trans, target_ease), player)
