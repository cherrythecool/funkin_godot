extends Node2D


@export var key_container: Node

@onready var keys: Array[Node] = key_container.get_children()

var button: Button
var key: StringName
var selected: int
var selecting: bool = false


func _ready() -> void:
	var binds: Dictionary = Settings.get_setting(&"core", "controls_keybinds")
	keys = keys.filter(func(node: Node) -> bool:
		return node is HBoxContainer
	)

	for node: Node in keys:
		for i: int in node.get_child_count() - 1:
			var n := node.get_node(str(i))
			if n is not Button:
				continue

			var b := n as Button
			b.text = OS.get_keycode_string(binds[node.name][i]).to_upper()
			b.pressed.connect(select_key.bind(b, node.name, i))
			b.focus_mode = Control.FOCUS_ACCESSIBILITY


func _input(event: InputEvent) -> void:
	if not selecting:
		return
	if event is not InputEventKey:
		return
	if event.is_echo() or not event.is_pressed():
		return

	get_viewport().set_input_as_handled()

	var input := event as InputEventKey
	var binds: Dictionary = Settings.get_setting(&"core", "controls_keybinds")
	binds[key][selected] = input.keycode
	button.text = OS.get_keycode_string(input.keycode).to_upper()
	Settings.set_setting(&"core", "controls_keybinds", binds)

	selecting = false


func select_key(b: Button, k: StringName, s: int) -> void:
	key = k
	selected = s
	button = b

	selecting = true
	button.text = "[Press a Key]"
	GlobalAudio.get_player(^'MENU/CONFIRM').play()
