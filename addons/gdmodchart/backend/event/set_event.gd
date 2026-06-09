class_name ModchartSetEvent extends ModchartEvent

var modifier: String
var player: int
var value: float

func run(_step: float) -> void:
	modchart_manager.set_value(modifier, value, player)
	finished = true
