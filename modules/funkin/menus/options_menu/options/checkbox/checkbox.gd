class_name CheckboxOption
extends Option


@onready var alphabet: Alphabet = $alphabet
@onready var checkbox: AnimatedSprite = $checkbox

@export var file: StringName = &"core"
@export var key: StringName = &"centered_receptors"

## Use this if you want your true / false to be replaced with some strings.
## Useful for things like downscroll that have a string direction name
## but have two main values (up and down).
##
## First value is for false and the second is for true.
@export var strings: Array[String] = []

var toggled: bool:
	set(value):
		if strings.size() >= 2:
			Settings.set_setting(file, key, strings[int(value)])
		else:
			Settings.set_setting(file, key, value)
	get:
		if strings.size() >= 2:
			return Settings.get_setting(file, key) == strings[1]
		else:
			return Settings.get_setting(file, key)


func _ready() -> void:
	if alphabet.centered:
		checkbox.position.x = (alphabet.size.x * 0.5) + 64.0
	else:
		checkbox.position.x = alphabet.size.x + 64.0
		checkbox.position.y = alphabet.size.y * 0.5

	checkbox.position.x += alphabet.position.x
	update_animation()


func _select() -> void:
	toggled = not toggled
	GlobalAudio.get_player(^'MENU/CONFIRM').play()
	update_animation()


func update_animation() -> void:
	if toggled:
		checkbox.play(&'selecting')
		checkbox.offset = Vector2(-5.0, -44.0)
	else:
		checkbox.play(&'unselected')
		checkbox.offset = Vector2.ZERO


func _on_checkbox_animation_finished() -> void:
	if checkbox.animation == &'selecting':
		checkbox.play(&'selected')
		checkbox.offset = Vector2(-3.0, -35.0)
