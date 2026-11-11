extends Label


var target_alpha: float = 0.25


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	modulate.a = target_alpha


func _process(delta: float) -> void:
	modulate.a = lerpf(modulate.a, target_alpha, FunkinUtils.lerp_weight(delta, 7.0))


func _on_mouse_entered() -> void:
	target_alpha = 1.0


func _on_mouse_exited() -> void:
	target_alpha = 0.25
