@tool
class_name TextureAtlasSprite
extends TextureAtlasFrameElement


const ROTATED_SPRITE_RADIANS: float = deg_to_rad(-90.0)

@export var key: StringName
@export var transform: Transform2D
@export var backbuffer_rect := Rect2()


static func parse(element: Dictionary, optimized: bool) -> TextureAtlasSprite:
	element = element.get("ASI" if optimized else "ATLAS_SPRITE_instance")

	var parsed := TextureAtlasSprite.new()
	parsed.key = StringName(element.get("N" if optimized else "name"))

	if element.has("MX" if optimized else "Matrix"):
		parsed.transform = TextureAtlas.parse_matrix(
			element.get("MX" if optimized else "Matrix")
		)
	else:
		parsed.transform = TextureAtlas.parse_matrix(
			element.get("M3D" if optimized else "Matrix3D")
		)

	return parsed


func calculate_rect(data: Dictionary[StringName, Variant]) -> void:
	var texture: Texture2D = data[&"texture"]
	var sprite_transform := Transform2D.IDENTITY
	if texture.get_meta(&"rotated", false) == true:
		sprite_transform = Transform2D(
			ROTATED_SPRITE_RADIANS,
			Vector2(
				0.0,
				texture.get_width(),
			),
		)

	rect = data[&"transform"] * transform * sprite_transform * Rect2(Vector2.ZERO, texture.get_size())
	backbuffer_rect = sprite_transform * Rect2(Vector2.ZERO, texture.get_size())


func draw(target: RID, options: Dictionary = {}) -> void:
	var texture: AtlasTexture = options[&"texture"]
	var sprite_transform := Transform2D.IDENTITY
	if texture.get_meta(&"rotated", false) == true:
		sprite_transform = Transform2D(
			ROTATED_SPRITE_RADIANS,
			Vector2(
				0.0,
				texture.get_width(),
			),
		)

	RenderingServer.canvas_item_add_set_transform(
		target,
		options[&"transform"] * transform * sprite_transform
	)

	texture.draw(target, Vector2.ZERO, options[&"modulate"])
