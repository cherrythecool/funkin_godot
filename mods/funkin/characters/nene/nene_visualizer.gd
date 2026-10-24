extends Node2D


@export var updates_per_second: float = 24.0
@export var targets: Array[AnimatedSprite2D]

@export_group("Analying Settings")
@export var min_db: float = 60.0
@export var max_hz: float = 11025.0

var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var update_timer: float = 0.0


func _ready() -> void:
	AudioServer.set_bus_effect_enabled(1, 0, true)
	spectrum_analyzer = AudioServer.get_bus_effect_instance(1, 0)
	update_visuals()


func _exit_tree() -> void:
	AudioServer.set_bus_effect_enabled(1, 0, false)


func _process(delta: float) -> void:
	update_timer += delta

	if update_timer >= 1.0 / updates_per_second:
		update_visuals()
		update_timer = 0.0


func update_visuals() -> void:
	var prev_hz: float = 0.0

	for i: int in targets.size():
		var hz := (float(i) * max_hz) / float(targets.size())
		var stereo_magnitudes := spectrum_analyzer.get_magnitude_for_frequency_range(prev_hz, hz)
		var mono_magnitude := stereo_magnitudes.length()
		var raw_energy := (min_db + linear_to_db(mono_magnitude)) / min_db
		var energy := clampf(raw_energy, 0.0, 1.0)

		if targets[i]:
			targets[i].frame = int(5.0 - (energy * 5.0))
		prev_hz = hz
