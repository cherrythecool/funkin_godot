extends CanvasLayer


@onready var label: Label = %performance_info
@onready var timer: Timer = %timer

var video_memory_peak: float = 0.0
var texture_memory_peak: float = 0.0
var static_memory_peak: float = 0.0
var info_mode: String = "minimal"

var tween: Tween
var times: Array[float] = []


func _ready() -> void:
	Settings.setting_changed.connect(_on_setting_changed)
	_update_from_settings()


func _process(delta: float) -> void:
	if visible:
		label.size = Vector2.ZERO

	times.push_back(delta)


func display() -> void:
	if not visible:
		return

	var video_memory_current: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	if video_memory_current > video_memory_peak:
		video_memory_peak = video_memory_current

	var texture_memory_current: float = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	if texture_memory_current > texture_memory_peak:
		texture_memory_peak = texture_memory_current

	var static_memory_current: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	if static_memory_current > static_memory_peak:
		static_memory_peak = static_memory_current

	var total_memory_current: float = video_memory_current + static_memory_current
	var total_memory_peak: float = video_memory_peak + static_memory_peak

	var scene_name: String = "N/A"
	var current_scene: Node = SceneManager.current_scene
	if is_instance_valid(current_scene):
		scene_name = current_scene.name

	var avg: float = 0.0
	for time: float in times:
		avg += time / float(times.size())

	times.clear()

	label.size = Vector2.ZERO

	var text_output: String = (
		"%d FPS (%.2fms)\n%s / %s %s\nFunkin' Godot v%s" % [
			Performance.get_monitor(Performance.TIME_FPS),
			avg * 1000.0,
			String.humanize_size(floori(total_memory_current)),
			String.humanize_size(floori(total_memory_peak)),
			"(CPU + GPU)" if static_memory_current > 0.0 else "<GPU>",
			Global.version,
		]
	)

	if info_mode == "full":
		text_output += "\n\n[Usage]\n%s / %s <GPU>\n%s / %s <TEX>\n%s / %s <CPU>\n\n[Engine]\nScene: %s\n%d Nodes (%d Orphaned)\nInput Accumulation: %s\n\n[Module]\nCurrent Module: %s\nSongs Folder: %s\n\n[Rendering]\n%d Draw Calls (%d Drawn Objects)\nAPI: %s (%s)\nGPU: %s" % [
			String.humanize_size(floori(video_memory_current)),
			String.humanize_size(floori(video_memory_peak)),
			String.humanize_size(floori(texture_memory_current)),
			String.humanize_size(floori(texture_memory_peak)),
			String.humanize_size(floori(static_memory_current)),
			String.humanize_size(floori(static_memory_peak)),
			scene_name,
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
			"on" if Input.use_accumulated_input else "off",
			ModuleManager.current_module,
			Game.songs_folder,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			RenderingServer.get_current_rendering_driver_name(),
			RenderingServer.get_current_rendering_method(),
			RenderingServer.get_video_adapter_name(),
		]

		if is_instance_valid(Conductor.instance):
			text_output += "\n\n[Conductor]\n%.2fms AudioServer Offset (raw)\n%.2fms Offset (%.2fms manual)\n%.3fs Time (%.2fx Speed)\n%.2f Beat, %.2f Step, %.2f Measure\n%.2f BPM" % [
				-AudioServer.get_output_latency() * 1000.0,
				Conductor.instance.offset * 1000.0,
				Conductor.instance.manual_offset * 1000.0,
				Conductor.instance.time, Conductor.instance.rate,
				Conductor.instance.beat, Conductor.instance.step, Conductor.instance.measure,
				Conductor.instance.tempo,
			]

		if is_instance_valid(Game.instance):
			text_output += "\n\n[Game]\n%.2f Scroll Speed\nIs Playing: %s\nHealth: %.2f\nCombo: %d" % [
				Game.instance.scroll_speed,
				Game.instance.playing,
				Game.instance.health,
				Game.instance.combo,
			]

	label.text = text_output


func _input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action(&"toggle_debug"):
		Settings.set_setting(&"core", "overlay_visible", not visible)
	if event.is_action(&"toggle_extra_info"):
		if info_mode == "minimal":
			info_mode = "full"
		else:
			info_mode = "minimal"

		Settings.set_setting(&"core", "overlay_mode", info_mode)


func _on_setting_changed(file: StringName, key: Variant) -> void:
	if file != &"core" or (key != "overlay_visible" and key != "overlay_mode"):
		return

	_update_from_settings()


func _update_from_settings() -> void:
	visible = Settings.get_setting(&"core", "overlay_visible", false)
	info_mode = Settings.get_setting(&"core", "overlay_mode", "minimal")

	if visible:
		_update_timer()
		display()
	else:
		timer.wait_time = 10.0


func _update_timer() -> void:
	match info_mode:
		"full":
			timer.wait_time = 0.2
		_:
			timer.wait_time = 1.0
