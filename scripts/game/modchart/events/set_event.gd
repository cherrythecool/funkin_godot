class_name ModchartSetEvent extends ModchartEvent

var modifier: String
var sub_modifier: String
var player: int
var value: float

func run(_step: float) -> void:
	if !sub_modifier.is_empty():
		modchart_manager.set_submod_value(modifier, sub_modifier, value, player)
	else:
		modchart_manager.set_value(modifier, value, player)
	finished = true
