extends Panel


@export var info_panel: Panel

var song := &""
var difficulty := &""
var active := false


func _ready() -> void:
	_update_visibility()


func _process(_delta: float) -> void:
	_update_visibility()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"freeplay_reset_score"):
		active = true

	if not active:
		return

	var axis := roundi(Input.get_axis(&"freeplay_no", &"freeplay_yes"))
	if axis != 0:
		active = false

	if axis == 1:
		Scores.reset_score(song, difficulty)
		info_panel._on_difficulty_changed(difficulty)


func _update_visibility() -> void:
	visible = active
