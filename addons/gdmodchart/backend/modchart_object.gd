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
	if self.modulate != origin.modulate + origin.self_modulate: self.modulate = origin.modulate + origin.self_modulate
	if self.scale.x != origin.global_scale.x or self.scale.y != origin.global_scale.y: self.scale = Vector3(origin.global_scale.x, origin.global_scale.y, 1)
	if self.texture_filter != _get_texture_filter(origin.texture_filter): self.texture_filter = _get_texture_filter(origin.texture_filter)
	self.offset = origin.offset
	self.visible = origin.visible
	
static func _get_texture_filter(filter:CanvasItem.TextureFilter):
	match filter:
		CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST: return  BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST
		_: return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR
		CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS: return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS: return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		CanvasItem.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC: return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
		CanvasItem.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC: return BaseMaterial3D.TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		CanvasItem.TextureFilter.TEXTURE_FILTER_MAX: return CanvasItem.TextureFilter.TEXTURE_FILTER_MAX

static func _get_origin_texture(origin:Variant) -> Texture2D:
	if !is_instance_valid(origin):
		return null
	if origin is Sprite2D:
		return origin.texture
	elif origin is AnimatedSprite2D && is_instance_valid(origin.sprite_frames):
		return origin.sprite_frames.get_frame_texture(origin.animation, origin.frame)
	return null
