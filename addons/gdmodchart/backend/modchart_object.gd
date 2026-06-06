extends Sprite3D
class_name ModchartObject

var origin:Node2D

func _init(origin:Node2D) -> void:
	self.origin = origin

func _process(delta: float) -> void:
	if !is_instance_valid(origin):
		self.queue_free()
		return
	self.texture = _get_origin_texture(origin)
	#if self.modulate != origin.modulate + origin.self_modulate: self.modulate = origin.modulate + origin.self_modulate
	self.offset = origin.offset
	
static func _get_origin_texture(origin:Variant) -> Texture2D:
	if !is_instance_valid(origin):
		return null
	if origin is Sprite2D:
		return origin.texture
	elif origin is AnimatedSprite2D && is_instance_valid(origin.sprite_frames):
		return origin.sprite_frames.get_frame_texture(origin.animation, origin.frame)
	return null
