extends CanvasLayer


@onready var info_labels: Dictionary[StringName, Label] = {
	&"performance": %performance_info,
	&"memory": %memory_info,
	&"engine": %engine_info,
	&"module": %module_info,
	&"rendering": %rendering_info,
	&"conductor": %conductor_info,
	&"game": %game_info,
}

@onready var timer: Timer = %timer

var info_mode := "minimal"
var object_mem_peak := 0.0
var video_mem_peak := 0.0
var texture_mem_peak := 0.0


func _ready() -> void:
	Settings.setting_changed.connect(_on_setting_changed)
	_update_settings()

	timer.start()
	timer.timeout.connect(_update_display)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_debug"):
		Settings.set_setting(&"core", "overlay_visible", not visible)
	elif event.is_action_pressed(&"toggle_extra_info"):
		if info_mode == "minimal":
			info_mode = "full"
		else:
			info_mode = "minimal"

		Settings.set_setting(&"core", "overlay_mode", info_mode)


func _on_setting_changed(file: StringName, key: Variant) -> void:
	if file != &"core" or (key != "overlay_visible" and key != "overlay_mode"):
		return

	_update_settings()


func _update_settings() -> void:
	visible = Settings.get_setting(&"core", "overlay_visible", false)
	info_mode = Settings.get_setting(&"core", "overlay_mode", "minimal")

	match info_mode:
		"full":
			timer.wait_time = 0.2

			for info: StringName in info_labels:
				info_labels[info].show()
		"minimal", _:
			timer.wait_time = 1.0

			for info: StringName in info_labels:
				if info != &"performance":
					info_labels[info].hide()
				else:
					info_labels[info].show()

	if visible:
		_update_display()
		timer.start()
	else:
		timer.stop()


func _update_display() -> void:
	if not visible:
		return

	for info: StringName in info_labels:
		if info_labels[info].visible:
			_update_label(info)


func _update_label(info_key: StringName) -> void:
	var label := info_labels[info_key]
	label.size = Vector2.ZERO

	match info_key:
		&"performance":
			var object_mem := Performance.get_monitor(Performance.MEMORY_STATIC)
			if object_mem > object_mem_peak:
				object_mem_peak = object_mem

			var video_mem := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
			if video_mem > video_mem_peak:
				video_mem_peak = video_mem

			var total_memory_current := object_mem + video_mem
			var total_memory_peak := object_mem_peak + video_mem_peak
			label.text = "FPS: %d\nMEM: %s / %s %s" % [
				Engine.get_frames_per_second(),
				String.humanize_size(floori(total_memory_current)),
				String.humanize_size(floori(total_memory_peak)),
				"(GPU)" if object_mem <= 0.0 else "",
			]
		&"memory":
			var object_mem := Performance.get_monitor(Performance.MEMORY_STATIC)
			if object_mem > object_mem_peak:
				object_mem_peak = object_mem

			var video_mem := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
			if video_mem > video_mem_peak:
				video_mem_peak = video_mem

			var texture_mem := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
			if texture_mem > texture_mem_peak:
				texture_mem_peak = texture_mem

			label.text = "OBJ: %s / %s\nGPU: %s / %s\nTEX: %s / %s" % [
				String.humanize_size(floori(object_mem)),
				String.humanize_size(floori(object_mem_peak)),
				String.humanize_size(floori(video_mem)),
				String.humanize_size(floori(video_mem_peak)),
				String.humanize_size(floori(texture_mem)),
				String.humanize_size(floori(texture_mem_peak)),
			]
		&"engine":
			var scene_name := &"(N/A)"
			var current_scene: Node = SceneManager.current_scene
			if is_instance_valid(current_scene):
				scene_name = current_scene.name

			label.text = "Scene: %s\nNodes: %d\nOrphan Nodes: %d\nInput Accumulation: %s" % [
				scene_name,
				floori(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				floori(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
				Input.use_accumulated_input,
			]
		&"module":
			label.text = "Module: %s\nSongs Folder: %s" % [
				ModuleManager.current_module,
				Game.load_settings[&"songs_folder"],
			]
		&"rendering":
			label.text = "API: %s/%s\nGPU: %s\nDraw Calls: %d\nDrawn Objects: %d" % [
				RenderingServer.get_current_rendering_driver_name(),
				RenderingServer.get_current_rendering_method(),
				RenderingServer.get_video_adapter_name(),
				floori(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				floori(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
			]
		&"conductor":
			label.text = "Time: %.3fs\nRate: %.2fx\nBPM: %.2f\nMeasure: %.2f\nBeat: %.2f\nStep: %.2f\nOffset: %.2fms" % [
				Conductor.time,
				Conductor.rate,
				Conductor.tempo,
				Conductor.measure,
				Conductor.beat,
				Conductor.step,
				Conductor.offset * 1000.0,
			]
		&"game":
			if not is_instance_valid(Game.instance):
				label.hide()
				return

			label.show()
			label.text = "Scroll Speed: %.2f\nPlaying: %s" % [
				Game.instance.scroll_speed,
				Game.instance.playing,
			]
