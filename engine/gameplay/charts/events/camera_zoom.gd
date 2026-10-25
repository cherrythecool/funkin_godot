class_name CameraZoom
extends EventData


enum ZoomMode {
	DIRECT = 0,
	STAGE
}


func _init(
	time_: float = 0.0,
	target_zoom: float = 1.05,
	duration: float = 32.0,
	ease_string: String = "linear",
	mode: ZoomMode = ZoomMode.DIRECT,
	multiplicative: bool = false,
) -> void:
	name = &"Camera Zoom"
	time = time_
	data[&"target_zoom"] = target_zoom
	data[&"duration"] = duration
	data[&"ease_string"] = ease_string
	data[&"mode"] = mode
	data[&"multiplicative"] = multiplicative
