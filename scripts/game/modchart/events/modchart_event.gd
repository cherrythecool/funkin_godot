class_name ModchartEvent extends Node

var start_step: float = 0

var modifier: String
var sub_modifier: String
var player: int

var value: float

var modchart_manager:ModchartManager

func _init(_modchart_manager: ModchartManager) -> void:
	modchart_manager = _modchart_manager

func run() -> void:
	_set_value()

func kill() -> void:
	queue_free()


func _get_value() -> float:
	if sub_modifier != null && !sub_modifier.is_empty():
		return modchart_manager.get_submod_value(modifier, sub_modifier, player)
	else:
		return modchart_manager.get_value(modifier, player)

func _set_value(_value:float = self.value) -> void:
	if sub_modifier != null && !sub_modifier.is_empty():
		modchart_manager.set_submod_value(modifier, sub_modifier, _value, player)
	else:
		modchart_manager.set_value(modifier, _value, player)
