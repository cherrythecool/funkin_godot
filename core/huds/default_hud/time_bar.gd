extends ProgressBar


@export_group("Custom Length", "custom_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var custom_length_enable: bool = false
@export var custom_length: float = 0.0

@onready var time_label: Label = $time_label


func _ready() -> void:
	visible = Settings.get_setting(&"core", "time_bar_show")
	update_bar_and_label()


func _process(_delta: float) -> void:
	if visible:
		update_bar_and_label()


func _on_hud_downscroll_changed(downscroll: bool) -> void:
	position.y = 720.0 - 16.0 - 14.0 if downscroll else 14.0


func update_bar_and_label() -> void:
	if Conductor.target_audio == null:
		value = 0.0
		time_label.text = "?:??"
		return

	var time := maxf(Conductor.time, 0.0)
	var length: float = custom_length if custom_length_enable else Conductor.target_length
	if Conductor.target_audio.playing and value < time:
		value = time

	max_value = length
	time_label.text = GameUtils.format_time(maxf(length - value, 0.0) / Conductor.rate)
