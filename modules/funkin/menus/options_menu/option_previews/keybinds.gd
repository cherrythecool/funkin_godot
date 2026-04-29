extends Node2D


@onready var keys: Array[Node] = get_children()
var selected: int = -1
var hovering: int = -1


func _ready() -> void:
	var binds: Dictionary = Settings.get_setting(&"core", "controls_keybinds")
	keys = keys.filter(func(node: Node) -> bool:
		return node is AnimatedSprite
	)

	for key: Node in keys:
		key.get_node('key').text = Alphabet.keycode_to_character(binds[key.name])
		key.modulate.a = 0.6
		key.set_meta(&"target_alpha", 0.6)


func _process(delta: float) -> void:
	for key: Node2D in keys:
		key.modulate.a = lerpf(key.modulate.a, key.get_meta(&"target_alpha", 0.6), delta * 9.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_motion(event)
	if event is InputEventMouseButton:
		_handle_button(event)
	if event is InputEventKey and selected != -1:
		_handle_key(event)


func _handle_key(event: InputEventKey) -> void:
	var key: Node = keys[selected]
	key.get_node('key').text = Alphabet.keycode_to_character(event.keycode)
	key.set_meta(&"target_alpha", 0.6)

	var binds: Dictionary = Settings.get_setting(&"core", "controls_keybinds")
	binds[key.name] = event.keycode
	Settings.set_setting(&"core", "controls_keybinds", binds)

	selected = -1
	GlobalAudio.get_player(^'MENU/CONFIRM').play()


func _handle_motion(event: InputEventMouseMotion) -> void:
	if selected != -1:
		return

	hovering = -1
	for i: int in keys.size():
		var key: Node2D = keys[i]
		var key_rect: Rect2 = Rect2(key.global_position.x - 50.0,
				key.global_position.y - 50.0,
				100.0, 100.0,)
		if key_rect.has_point(event.global_position):
			key.set_meta(&"target_alpha", 1.0)
			hovering = i
		else:
			key.set_meta(&"target_alpha", 0.6)


func _handle_button(event: InputEventMouseButton) -> void:
	if hovering == -1:
		return
	if not event.pressed:
		return

	selected = hovering
	keys[selected].get_node('key').text = '#'
	GlobalAudio.get_player(^'MENU/CONFIRM').play()
