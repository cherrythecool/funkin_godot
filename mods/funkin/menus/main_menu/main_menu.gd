class_name MainMenu
extends Node2D


static var selected: int = 0
static var freeplay_scene: String = 'uid://3rua2gpac5p8'

@export var button_container: VBoxContainer
@export var background_animations: AnimationPlayer
@export var camera: Camera2D
@export var button_timer: Timer

var active: bool = true


func _ready() -> void:
	if not MenuAudio.music.playing:
		MenuAudio.music.play()

	# thank you https://github.com/godotengine/godot-proposals/issues/12058#issuecomment-2748489241
	# needed to recompute the layout manually to make sure that
	# positions of the buttons would be fine... :sob:
	button_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
	change_selection()

	camera.reset_smoothing()
	camera.force_update_scroll()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed(&"menu_up") or event.is_action_pressed(&"menu_down"):
		change_selection(roundi(Input.get_axis(&"menu_up", &"menu_down")))

	if event.is_action_pressed(&"menu_cancel"):
		MenuAudio.cancel.play()
		active = false
		SceneManager.transition_to_file("uid://cxk008iuw4n7u")

	if event.is_action_pressed(&"menu_accept"):
		MenuAudio.confirm.play()
		active = false
		_press_animation()

		var item := button_container.get_child(selected) as MainMenuButton
		item.press()
		button_timer.start(0.0)
		button_timer.timeout.connect(_on_press.bind(item), CONNECT_ONE_SHOT)


func _on_press(item: MainMenuButton) -> void:
	if not item.accept():
		MenuAudio.cancel.play()
		active = true
		_cancel_animation()


func _press_animation() -> void:
	if Settings.get_setting(&"core", "flashing_lights"):
		background_animations.play(&"loop")

	var tween := create_tween()\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)\
		.set_parallel()

	for i: int in button_container.get_child_count():
		if i == selected:
			continue

		tween.tween_property(button_container.get_child(i), ^"modulate:a", 0.0, 0.25)


func _cancel_animation() -> void:
	background_animations.seek(0.0, true)
	background_animations.stop()

	var tween := create_tween()\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)\
		.set_parallel()

	for i: int in button_container.get_child_count():
		if i == selected:
			continue

		tween.tween_property(button_container.get_child(i), ^"modulate:a", 1.0, 0.25)


func change_selection(amount: int = 0) -> void:
	var previous_item := button_container.get_child(selected) as MainMenuButton
	previous_item.sprite.play(&"%s idle" % previous_item.animation_name)
	previous_item.z_index = 0

	selected = wrapi(selected + amount, 0, button_container.get_child_count())

	var current_item := button_container.get_child(selected) as MainMenuButton
	current_item.sprite.play(&"%s selected" % current_item.animation_name)
	current_item.z_index = 1
	camera.position.y = current_item.global_position.y

	if amount != 0:
		MenuAudio.scroll.play()
