class_name ModchartFunctionEvent extends ModchartEvent

var end_step: int = 0
var function: Callable

func run(_step: float) -> void:
	function.call()
	if _step >= end_step:
		finished = true
