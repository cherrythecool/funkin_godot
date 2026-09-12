extends CanvasLayer


func _ready() -> void:
	if (
		Settings.get_setting(&"core", "performance_mode") or
		not Settings.get_setting(&"core", "flashing_lights")
	):
		queue_free()
