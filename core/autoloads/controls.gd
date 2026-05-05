extends Node


func _ready() -> void:
	Settings.setting_changed.connect(_on_setting_changed)
	update_bindings()


func update_bindings() -> void:
	var binds: Dictionary = Settings.get_setting(&"core", "controls_keybinds")

	for key: String in binds.keys():
		var action: StringName = StringName(key)
		var action_events := InputMap.action_get_events(action)
		var keycodes: Array = binds[key]

		for i: int in keycodes.size():
			InputMap.action_erase_event(action, action_events.pop_back())

		for i: int in keycodes.size():
			var event: InputEventKey = InputEventKey.new()
			event.keycode = keycodes[i]
			InputMap.action_add_event(action, event)


func _on_setting_changed(file: StringName, key: Variant) -> void:
	if file != &"core" and key != "controls_keybinds":
		return

	update_bindings()
