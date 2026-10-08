extends Node


func _ready() -> void:
	SaveData.save_changed.connect(_on_save_changed)
	update_bindings()


func update_bindings() -> void:
	var binds: Dictionary = SaveData.get_save_value(&"core", "controls_keybinds")

	for action_name: String in binds.keys():
		var action := StringName(action_name)
		var action_events := InputMap.action_get_events(action)
		var keycodes: Array = binds[action_name]

		for i: int in keycodes.size():
			InputMap.action_erase_event(action, action_events.pop_back())

		for i: int in keycodes.size():
			var event := InputEventKey.new()
			event.keycode = keycodes[i]
			InputMap.action_add_event(action, event)


func _on_save_changed(file: StringName, key: Variant) -> void:
	if file != &"core" and key != "controls_keybinds":
		return

	update_bindings()
