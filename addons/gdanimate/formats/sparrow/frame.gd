@tool
class_name SparrowFrame
extends Resource


@export var name := &""
@export var region := Rect2()
@export var offset := Rect2()
@export var rotated := false


static func sort_by_name(a: SparrowFrame, b: SparrowFrame) -> bool:
	return String(a.name) < String(b.name)


static func get_filtered_frame(
	prefix: String,
	frame: int,
	atlas: SparrowAtlas,
) -> SparrowFrame:
	var frame_cache: Dictionary[String, Array] = atlas._internal_frames_cache

	if atlas.frames.is_empty():
		return null
	if not frame_cache.has(prefix):
		frame_cache[prefix] = get_filtered_frames(prefix, atlas)

	var filtered := frame_cache[prefix] as Array[SparrowFrame]
	if filtered.is_empty():
		return null
	else:
		return filtered[mini(frame, filtered.size() - 1)]


static func get_filtered_frames(
	filter: String,
	atlas: SparrowAtlas,
) -> Array[SparrowFrame]:
	if filter.strip_edges().is_empty():
		return atlas.frames.duplicate()

	return atlas.frames.filter(func(frame: SparrowFrame) -> bool:
		if not atlas.symbols.has(filter):
			return frame.name.begins_with(filter)

		return (
			frame.name.left(frame.name.length() - 4) == filter and
			frame.name.right(4).is_valid_int()
		)
	)


func draw_2d(canvas_item: RID, texture: Texture2D, draw_offset: Vector2) -> void:
	draw_offset -= offset.position

	if rotated:
		RenderingServer.canvas_item_add_set_transform(
			canvas_item,
			Transform2D(
				-PI / 2.0,
				Vector2(
					draw_offset.x,
					region.size.x + draw_offset.y
				),
			),
		)
	else:
		RenderingServer.canvas_item_add_set_transform(
			canvas_item,
			Transform2D(
				0.0,
				draw_offset,
			),
		)

	RenderingServer.canvas_item_add_texture_rect_region(
		canvas_item,
		Rect2(
			Vector2.ZERO,
			region.size,
		),
		texture,
		region,
	)


func parse(xml: XMLParser) -> void:
	name = xml.get_named_attribute_value_safe("name")
	region = Rect2(
		Vector2(
			xml.get_named_attribute_value_safe("x").to_float(),
			xml.get_named_attribute_value_safe("y").to_float(),
		),
		Vector2(
			xml.get_named_attribute_value_safe("width").to_float(),
			xml.get_named_attribute_value_safe("height").to_float(),
		)
	)

	if xml.has_attribute("frameX") and xml.has_attribute("frameY"):
		offset.position = Vector2(
			xml.get_named_attribute_value_safe("frameX").to_float(),
			xml.get_named_attribute_value_safe("frameY").to_float(),
		)
	else:
		offset.position = Vector2.ZERO

	if xml.has_attribute("frameWidth") and xml.has_attribute("frameHeight"):
		offset.size = Vector2(
			xml.get_named_attribute_value_safe("frameWidth").to_float(),
			xml.get_named_attribute_value_safe("frameHeight").to_float(),
		)
	else:
		offset.size = region.size

	rotated = xml.get_named_attribute_value_safe("rotated") == "true"


func get_bounding_box() -> Rect2:
	if rotated:
		return Rect2(
			-offset.position,
			Vector2(
				region.size.y,
				region.size.x,
			)
		)
	else:
		return Rect2(
			-offset.position,
			region.size
		)


func get_name_array() -> Array[Variant]:
	if name.length() < 4:
		return [name]

	var numbers_string := name.right(4)
	if numbers_string.is_valid_int():
		var animation_name := name.left(-4)
		return [animation_name, numbers_string.to_int()]
	else:
		return [name]
