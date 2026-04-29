extends Node


func _ready() -> void:
	Settings.setting_changed.connect(_on_setting_changed)
	update_bindings()


func update_bindings() -> void:
	var binds: Dictionary = Settings.get_setting(&"core", "controls_keybinds")

	for key: String in binds.keys():
		var action: StringName = StringName(key)
		var action_events := InputMap.action_get_events(action)

		# erase last event to prepare our new one
		InputMap.action_erase_event(action, action_events.pop_back())

		var event: InputEventKey = InputEventKey.new()
		event.keycode = binds[key]
		InputMap.action_add_event(action, event)


func _on_setting_changed(file: StringName, key: Variant) -> void:
	if file != &"core" and key != "controls_keybinds":
		return

	update_bindings()
