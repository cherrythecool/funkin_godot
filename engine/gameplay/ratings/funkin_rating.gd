class_name FunkinRating
extends Resource


@export var name: StringName = &"marvelous"
@export_range(0.0, 180.0, 0.01) var threshold_millis: float = 22.5
@export_range(0, 1000, 1, "or_less") var score: int = 350
@export_range(-10.0, 10.0, 0.01, "or_less", "or_greater") var health_percent: float = 1.15
@export var accuracy_percent: float = 100.0
