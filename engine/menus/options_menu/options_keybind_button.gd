extends Button


static var selected: Control = null

@export var key: String = "note_left"
@export var index: int = 0


func _ready() -> void:
	var keybinds: Dictionary = SaveData.get_save_value(&"core", "controls_keybinds", {})
	text = OS.get_keycode_string(keybinds.get(key, [])[index])


func _exit_tree() -> void:
	if selected == self:
		selected = null


func _input(event: InputEvent) -> void:
	if selected != self or event is not InputEventKey or event.is_echo() or not event.is_pressed():
		return

	event = event as InputEventKey
	text = OS.get_keycode_string(event.keycode)
	selected = null

	var keybinds: Dictionary = SaveData.get_save_value(&"core", "controls_keybinds", {})
	keybinds[key][index] = event.keycode
	SaveData.set_save_value(&"core", "controls_keybinds", keybinds)


func _pressed() -> void:
	if selected:
		return

	selected = self
	text = "..."
