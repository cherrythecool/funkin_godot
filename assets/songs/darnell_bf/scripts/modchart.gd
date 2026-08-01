extends FunkinScript


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var modchart:ModchartManager = ModchartManager.new(preload("res://scripts/game/modchart_handler.gd"))
	modchart.set_percent("beat", 100)
