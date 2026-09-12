extends CanvasLayer


@export_group("Modes")
@export var menus: Control
@export var freeplay: Control
@export var game: Control

@export_group("Gameplay Buttons")
@export var left: ColorRect
@export var down: ColorRect
@export var up: ColorRect
@export var right: ColorRect

var rects: Array[ColorRect]
var states: Array[bool] = [false, false, false, false]


func _ready() -> void:
	if not Global.is_mobile:
		queue_free()
		return

	rects = [left, down, up, right]

	for i: int in rects.size():
		var rect := rects[i]
		var button: TouchScreenButton = rect.get_node(^"Button")
		button.pressed.connect(func() -> void:
			states[i] = true
		)
		button.released.connect(func() -> void:
			states[i] = false
		)


func _process(delta: float) -> void:
	for i: int in states.size():
		if states[i]:
			rects[i].color.a = 0.3
		else:
			rects[i].color.a = lerpf(rects[i].color.a, 0.0, delta * 6.0)

	if not is_instance_valid(SceneManager.current_scene):
		return

	var current: Node = SceneManager.current_scene
	if current is Game and current.process_mode == Node.PROCESS_MODE_DISABLED:
		menus.visible = true
	else:
		menus.visible = current is not Game
	freeplay.visible = current is FreeplayMenu
	game.visible = not menus.visible


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		fake_action_press(&"game_pause" if game.visible else &"menu_cancel")


func fake_input(action: StringName, press: bool) -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = press
	Input.parse_input_event(ev)


func fake_action_press(action: StringName) -> void:
	fake_input(action, true)
	fake_input(action, false)
