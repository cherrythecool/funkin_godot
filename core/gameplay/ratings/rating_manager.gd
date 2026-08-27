@abstract
class_name RatingManager
extends Node


@warning_ignore("unused_signal")
signal changed


@abstract
func get_health_percent() -> float


@abstract
func add_note_hit(time_diff: float) -> void


@abstract
func add_note_miss() -> void
