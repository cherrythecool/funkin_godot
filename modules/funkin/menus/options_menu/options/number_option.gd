class_name NumberOption
extends PreviewOption


@export var file: StringName = &"core"
@export var key: StringName = &"note_offset"

@export var integers: bool = true
@export var ranged: bool = false

@export var minimum: float = -10.0
@export var maximum: float = 10.0
@export var step: float = 1.0
@export var step_shift: float = 0.0
@export var step_alt: float = 0.0

@export var shift_speed: float = 1.0
@export var alt_speed: float = 3.0

@export var value_suffix: StringName = &""

@export var increment_delay: float = 0.1
@export var root: Node

@export var display_as_percent: bool = false

@onready var value_label: Alphabet = $value

var timer: float = 0.0
var value: float:
	set(new_value):
		var final_value: Variant = new_value
		if display_as_percent:
			final_value *= 100.0
		if integers:
			final_value = int(final_value)

		if display_as_percent:
			set_value(final_value / 100.0)
		else:
			set_value(final_value)

		value = new_value

		var left: String = "< " if selected else ""
		var right: String = " >" if selected else ""

		if integers:
			value_label.text = "%s%d%s%s" % [left, final_value, value_suffix, right]
		else:
			value_label.text = "%s%s%s%s" % [left,
					str(snapped(final_value, step)).pad_decimals(1), value_suffix, right]

		GlobalAudio.get_player(^"MENU/SCROLL").play()
		_value_changed()


func _ready() -> void:
	super()

	value = Settings.get_setting(file, key)
	assert(is_instance_valid(root), "No root given to number option. This could cause issues, so here is your error.")


func _select() -> void:
	super()

	selected = not selected
	root.active = not selected
	value = value


func _process(delta: float) -> void:
	if not selected:
		return

	var axis: float = Input.get_axis(&"menu_left", &"menu_right")
	if axis == 0.0:
		timer = 0.0
		return

	if Input.is_action_just_pressed(&"menu_left") or Input.is_action_just_pressed(&"menu_right"):
		timer = increment_delay

	timer += delta
	var delay_modifier: float = (1.0 +
			(float(Input.is_action_pressed(&"shift")) * shift_speed) +
			(float(Input.is_action_pressed(&"alt")) * alt_speed))

	var increment: float = step
	if Input.is_action_pressed(&"alt") and step_alt > 0.0:
		increment = step_alt
	elif Input.is_action_pressed(&"shift") and step_shift > 0.0:
		increment = step_shift

	if timer >= increment_delay / delay_modifier:
		timer = 0.0
		if ranged:
			value = clampf(value + axis * increment, minimum, maximum)
		else:
			value += axis * increment


func _unhandled_input(event: InputEvent) -> void:
	if not selected:
		return
	if not event.is_pressed():
		return
	if event.is_echo():
		return

	if event.is_action(&"menu_accept") or event.is_action(&"menu_cancel"):
		get_viewport().set_input_as_handled()
		_select()
		GlobalAudio.get_player(^"MENU/CONFIRM").play()


func set_value(value_: Variant) -> void:
	Settings.set_setting(file, key, value_)


func _value_changed() -> void:
	pass
