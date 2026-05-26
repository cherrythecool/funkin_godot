extends Node2D
class_name CategoryBase


var selected: int = 0
var alive: bool = false:
	set(value):
		visible = value

		if value:
			_activate()
	get:
		return visible
var active: bool = true


func _ready() -> void:
	alive = true


func _unhandled_input(event: InputEvent) -> void:
	if not (active and alive):
		return
	if not event.is_pressed():
		return
	if event.is_action(&'menu_cancel'):
		get_viewport().set_input_as_handled()
		active = false

		# TODO: fix this because it's like... really bad code-style lol
		SceneManager.current_scene.deselect_current()
		return


func _activate() -> void:
	pass


func _on_timer_timeout() -> void:
	active = true
