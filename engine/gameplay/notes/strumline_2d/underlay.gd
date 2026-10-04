extends ColorRect


func _ready() -> void:
	modulate.a = Settings.get_setting(&"core", "note_underlay_alpha", 0.0)
