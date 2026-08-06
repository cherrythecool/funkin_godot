@tool
@abstract
class_name TextureAtlasFrameElement
extends Resource


@export var rect := Rect2()


@abstract
func calculate_rect(data: Dictionary[StringName, Variant]) -> void
