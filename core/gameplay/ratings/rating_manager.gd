@abstract
class_name RatingManager
extends Node


@warning_ignore_start("unused_signal")
signal died
signal changed
@warning_ignore_restore("unused_signal")


func _process(_delta: float) -> void:
	if get_health_percent() <= 0.0:
		_died()
		died.emit()


@abstract
func get_health_percent() -> float


@abstract
func add_note_hit(time_diff: float) -> void


@abstract
func add_note_miss() -> void


@abstract
func _died() -> void
