extends Node


const MAX_DESYNC: float = 20.0 / 1000.0

static var instance: Conductor = null

static var audio_offset: float:
	get:
		return AudioServer.get_output_latency()

static var manual_offset: float = 0.0
static var offset: float = audio_offset + manual_offset

@export var rate: float = 1.0:
	set(value):
		Engine.time_scale = maxf(value, 0.0)

		if is_instance_valid(target_audio):
			target_audio.pitch_scale = value

		internal_rate = value
		rate_changed.emit(value)
	get:
		if is_instance_valid(target_audio):
			return target_audio.pitch_scale
		else:
			return internal_rate

@export var active: bool = true
@export var tempo: float = 0.0

var timing_changes: Array[TimingChange] = []

var raw_time: float = 0.0

var time: float:
	get:
		return raw_time - offset

# We need this internal variable to let you
# properly modify rate in editor export at runtime
var internal_rate: float = 1.0

var beat: float = 0.0

## TODO: Time signatures
var step: float:
	get:
		return beat * 4.0

var measure: float:
	get:
		return beat / 4.0

var beat_delta: float:
	get:
		return 60.0 / tempo

var sustain_release_delta: float:
	get:
		return beat_delta / 2.0

var step_delta: float:
	get:
		return beat_delta / 4.0

var measure_delta: float:
	get:
		return beat_delta * 4.0

@export var target_audio: AudioStreamPlayer = null:
	set(value):
		if target_audio != value:
			target_audio = value
			Engine.time_scale = maxf(rate, 0.0)

var target_length: float:
	get:
		if is_instance_valid(target_audio) and is_instance_valid(target_audio.stream):
			return target_audio.stream.get_length()
		else:
			return 1.0

signal step_hit(step: int)
signal beat_hit(beat: int)
signal measure_hit(measure: int)
signal rate_changed(rate: float)


func _exit_tree() -> void:
	if instance == self:
		rate = 1.0
		instance = null


func _ready() -> void:
	if not is_instance_valid(instance):
		instance = self

	Settings.setting_changed.connect(_on_setting_changed)
	SceneManager.scene_changed.connect(_on_scene_changed)


func _process(delta: float) -> void:
	if not active:
		return

	if is_instance_valid(target_audio):
		sync_to_target(delta)
	else:
		raw_time += delta

	calculate_beat()


func _on_setting_changed(file: StringName, key: Variant) -> void:
	if file == &"core" and key == "note_offset":
		manual_offset = Settings.get_setting(file, key) / 1000.0


func _on_scene_changed() -> void:
	reset_offset()


func get_tempo_at_time(time_: float, timing_changes_: Array[TimingChange]) -> float:
	if timing_changes_.is_empty():
		return 0.0

	var bpm: float = timing_changes_[0].bpm
	for change: TimingChange in timing_changes_:
		if maxf(time_, 0.0) < change.time:
			break
		if not change.bpm_changed:
			continue

		bpm = change.bpm

	return bpm


func get_beat_at_time(time_: float, timing_changes_: Array[TimingChange]) -> float:
	if timing_changes_.is_empty():
		return 0.0

	var beat_: float = 0.0
	var bpm: float = timing_changes_[0].bpm

	var last_time: float = 0.0
	for change: TimingChange in timing_changes_:
		if maxf(time_, 0.0) < change.time:
			break
		if not change.bpm_changed:
			continue

		beat_ += (change.time - last_time) / (60.0 / bpm)
		last_time = change.time
		bpm = change.bpm

	beat_ += (time_ - last_time) / (60.0 / bpm)
	return beat_


func sync_to_target(delta: float) -> void:
	var audio_time := GameUtils.get_accurate_time(target_audio)
	if target_audio.playing and absf(raw_time - audio_time) < 0.5:
		raw_time = maxf(audio_time, raw_time + (delta * 0.9))
	else:
		raw_time = audio_time


func calculate_beat() -> void:
	var last_step: int = floori(step)
	var last_beat: int = floori(beat)
	var last_measure: int = floori(measure)

	if timing_changes.is_empty():
		beat = time / beat_delta
	else:
		tempo = get_tempo_at_time(time, timing_changes)
		beat = get_beat_at_time(time, timing_changes)

	calculate_hits(last_step, last_beat, last_measure)


func calculate_hits(last_step: int, last_beat: int, last_measure: int) -> void:
	if floori(step) > last_step:
		for step_value: int in range(last_step + 1, floori(step) + 1):
			step_hit.emit(step_value)
	if floori(beat) > last_beat:
		for beat_value: int in range(last_beat + 1, floori(beat) + 1):
			beat_hit.emit(beat_value)
	if floori(measure) > last_measure:
		for measure_value: int in range(last_measure + 1, floori(measure) + 1):
			measure_hit.emit(measure_value)


func append_timing_changes(events: Array[TimingChange], clear: bool = true) -> void:
	if clear:
		timing_changes.clear()

	timing_changes.append_array(events)
	timing_changes.sort_custom(Chart.sort_by_time)


func reset() -> void:
	reset_offset()
	target_audio = null
	raw_time = 0.0
	timing_changes.clear()
	calculate_beat()


func reset_offset() -> void:
	offset = audio_offset + manual_offset
