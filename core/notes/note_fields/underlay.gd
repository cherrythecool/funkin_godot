extends ColorRect


func _ready() -> void:
	color.a = Settings.get_setting(&"core", "note_underlay_alpha")
