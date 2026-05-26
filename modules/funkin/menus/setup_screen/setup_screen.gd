extends Node2D


@export var options: Array[Node2D] = []
var selected: int = 0
var active: bool = true


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_echo():
		return
	if not event.is_pressed():
		return

	if event.is_action(&"menu_left") or event.is_action(&"menu_right"):
		change_selection(roundi(Input.get_axis(&"menu_left", &"menu_right")))
	if event.is_action(&"menu_up") or event.is_action(&"menu_down"):
		change_selection(roundi(Input.get_axis(&"menu_up", &"menu_down")))

	if event.is_action(&"menu_accept"):
		active = false
		GlobalAudio.get_player(^"MENU/CONFIRM").play()

		match options[selected].name:
			&"yes":
				OptionsMenu.target_scene = "uid://cxk008iuw4n7u"
				SceneManager.transition_to_packed(load("uid://3daku38i1a50"))
			&"no":
				SceneManager.transition_to_packed(load("uid://cxk008iuw4n7u"))

	if event.is_action(&"menu_cancel"):
		active = false
		GlobalAudio.get_player(^"MENU/CANCEL").play()
		SceneManager.transition_to_packed(load("uid://cxk008iuw4n7u"))


func change_selection(amount: int = 0) -> void:
	options[selected].modulate.a = 0.5
	selected = wrapi(selected + amount, 0, options.size())
	options[selected].modulate.a = 1.0

	if amount != 0:
		GlobalAudio.get_player(^"MENU/SCROLL").play()
