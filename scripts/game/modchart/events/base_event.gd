class_name ModchartEvent extends Node

var exec_step: float = 0

var modchart_manager: ModchartManager
var timeline: ModchartTimeline

var ignore_exec: bool = false
var finished: bool = false

func _init(_modchart_manager: ModchartManager, _timeline: ModchartTimeline) -> void:
	modchart_manager = _modchart_manager
	timeline = _timeline

@warning_ignore("unused_parameter")
func run(step: float) -> void: pass
