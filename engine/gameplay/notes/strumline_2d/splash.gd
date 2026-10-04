extends AnimatedSprite2D


func _ready() -> void:
	animation_finished.connect(hide)
	hide()

	modulate.a = Settings.get_setting(&"core", "note_splash_alpha", 0.8)
