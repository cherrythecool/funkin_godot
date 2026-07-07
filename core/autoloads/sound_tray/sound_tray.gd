extends CanvasLayer


@onready var bars: TextureRect = %bars
@onready var root: Control = %root
@onready var background: TextureRect = %background
@onready var animation_player: AnimationPlayer = %animation_player
@onready var bounce_player: AnimationPlayer = %bounce_player
@onready var close_timer: Timer = %close_timer

@onready var volume_up: AudioStreamPlayer = %volume_up
@onready var volume_down: AudioStreamPlayer = %volume_down
@onready var volume_max: AudioStreamPlayer = %volume_max

var muted: bool = false:
	set(value):
		AudioServer.set_bus_mute(0, value)
	get:
		return AudioServer.is_bus_mute(0)

var volume: float = -1.0:
	set(value):
		if volume == value:
			return

		AudioServer.set_bus_volume_db(
			0,
			linear_to_db(value),
		)

		var buses: Dictionary = Settings.get_setting(&"core", "volume", {})
		buses[&"Master"] = value
		Settings.set_setting(&"core", "volume", buses)

		if volume > 0.0:
			muted = false
	get:
		return db_to_linear(AudioServer.get_bus_volume_db(0))

var shake_timer: float = 0.0


func _ready() -> void:
	hide()
	Settings.settings_loaded.connect(_on_settings_loaded)


func _physics_process(delta: float) -> void:
	shake_timer -= delta

	if shake_timer >= 0.0:
		root.position = Vector2(
			randf_range(-2.0, 2.0),
			randf_range(-2.0, 2.0)
		)
	else:
		root.position = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if not (
		event.is_action(&"volume_down") or
		event.is_action(&"volume_up") or
		event.is_action(&"volume_mute")
	):
		return

	var direction := roundi(Input.get_axis(&"volume_down", &"volume_up"))
	if direction == 0 and not event.is_action(&"volume_mute"):
		return

	if background.position.y <= -128.0 or animation_player.current_animation == &"close":
		close_timer.stop()
		animation_player.play(&"open")
		animation_player.seek(0.0, true)

	close_timer.start()

	if not event.is_action(&"volume_mute"):
		bounce_player.play(&"bounce")
		bounce_player.seek(0.0, true)
	else:
		muted = not muted
		shake_timer = randf_range(0.1, 0.2)

	visible = true

	if Input.is_action_pressed(&"shift"):
		volume = clampf(volume + 0.01 * direction, 0.0, 1.0)
	else:
		volume = clampf(volume + 0.05 * direction, 0.0, 1.0)

	if volume == 1.0 and direction != 0.0:
		shake_timer = randf_range(0.1, 0.2)
		volume_max.play()
	else:
		if direction > 0.0:
			volume_up.play()
			volume_up.pitch_scale = lerpf(0.85, 1.15, volume)
		elif direction < 0.0:
			volume_down.play()
			volume_down.pitch_scale = lerpf(0.85, 1.15, volume)

	bars.texture.region.size.x = bars.texture.atlas.get_width() * volume
	if bars.texture.region.size.x < 1.0:
		bars.texture.region.size.x = 1.0

	bars.modulate = Color.INDIAN_RED if muted else Color.WHITE


func _on_settings_loaded(file: StringName) -> void:
	if file != &"core":
		return

	var buses: Dictionary = Settings.get_setting(&"core", "volume", {})
	for bus: String in buses.keys():
		var bus_index: int = AudioServer.get_bus_index(bus)
		if bus_index < 0:
			continue

		AudioServer.set_bus_volume_db(bus_index, linear_to_db(buses.get(bus, 1.0)))


func _on_tray_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"open":
		close_timer.start()


func _on_close_timer_timeout() -> void:
	animation_player.play(&"close")
