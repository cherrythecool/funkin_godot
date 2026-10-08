extends AnimatedSprite2D


func _ready() -> void:
	animation_finished.connect(hide)
	hide()

	modulate.a = SaveData.get_save_value(&"core", "note_splash_alpha", 0.8)
