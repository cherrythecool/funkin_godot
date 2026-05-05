extends CategoryBase


@onready var selected_option: CheckboxOption = $flashing_lights



func _input(event: InputEvent) -> void:
	if not (active and alive):
		return
	if not event.is_pressed():
		return
	if event.is_echo():
		return

	super(event)

	if event.is_action('menu_accept'):
		selected_option._select()
