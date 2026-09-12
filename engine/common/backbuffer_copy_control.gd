@tool
class_name BackBufferCopyControl
extends Control


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	RenderingServer.canvas_item_set_copy_to_backbuffer(
		get_canvas_item(),
		is_visible_in_tree(),
		(
			get_backbuffer_transform() * (Rect2(Vector2.ZERO, get_rect().size))
		) if not Engine.is_editor_hint() else Rect2()
	)


func get_backbuffer_transform() -> Transform2D:
	return get_viewport().get_stretch_transform() * get_global_transform_with_canvas()
