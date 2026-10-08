extends ColorRect


func _ready() -> void:
	modulate.a = SaveData.get_save_value(&"core", "note_underlay_alpha", 0.0)
