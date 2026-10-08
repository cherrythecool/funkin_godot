extends Panel


@export var info_panel: Panel

var song := &""
var difficulty := &""


func _ready() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"freeplay_reset_score"):
		show()

	if not visible:
		return

	var axis := roundi(Input.get_axis(&"freeplay_no", &"freeplay_yes"))
	if axis != 0:
		hide()

	if axis == 1:
		Highscores.reset_score(song, difficulty)
		info_panel._on_difficulty_changed(difficulty)
