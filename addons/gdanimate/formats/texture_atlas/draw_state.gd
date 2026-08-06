@tool
class_name TextureAtlasDrawState
extends RefCounted


var item_pool: Array[RID]
var item_pool_index: int = 0

var texture_filter: RenderingServer.CanvasItemTextureFilter
var texture_repeat: RenderingServer.CanvasItemTextureRepeat
var light_mask: int = 1

var materials: Dictionary[StringName, Material] = {}

var backbuffer_transform := Transform2D.IDENTITY
var local_transform := Transform2D.IDENTITY

var bounding_box := Rect2()
var item_bounding_box := Rect2()
var bounding_box_cache: Dictionary[RID, Rect2]

var blend_mode := TextureAtlas.BlendMode.NORMAL
var item_blend_mode := TextureAtlas.BlendMode.NORMAL

var color_matrix := TextureAtlasColorMatrix.new()
var item_color_matrix := color_matrix

var masked := false
var item_masked := false
var masked_items: Array[RID]

var masker := false
var item_masker := false


func get_backbuffer_rect() -> Rect2:
	if not Engine.is_editor_hint():
		return backbuffer_transform * bounding_box
	else:
		return Rect2()


func blend_needs_backbuffer(blend: TextureAtlas.BlendMode) -> bool:
	match blend:
		TextureAtlas.BlendMode.SUBTRACT:
			return not (materials.has(&"blend_subtract") and is_instance_valid(materials[&"blend_subtract"]))
		TextureAtlas.BlendMode.ADD:
			return not (materials.has(&"blend_add") and is_instance_valid(materials[&"blend_add"]))
		TextureAtlas.BlendMode.NORMAL:
			return not (materials.has(&"default") and is_instance_valid(materials[&"default"]))
		_:
			return true


func get_material(blend: TextureAtlas.BlendMode) -> RID:
	match blend:
		TextureAtlas.BlendMode.SUBTRACT:
			if materials.has(&"blend_subtract") and is_instance_valid(materials[&"blend_subtract"]):
				return materials[&"blend_subtract"].get_rid()
		TextureAtlas.BlendMode.ADD:
			if materials.has(&"blend_add") and is_instance_valid(materials[&"blend_add"]):
				return materials[&"blend_add"].get_rid()
		TextureAtlas.BlendMode.NORMAL:
			if materials.has(&"default") and is_instance_valid(materials[&"default"]):
				return materials[&"default"].get_rid()

	return _get_other_blends_material()


func get_current_item() -> RID:
	if item_pool.is_empty():
		return RID()
	else:
		return item_pool[item_pool_index]


func get_next_item() -> RID:
	item_pool_index += 1

	var rid: RID
	if item_pool_index >= item_pool.size():
		item_pool_index = item_pool.size()

		rid = RenderingServer.canvas_item_create()
		item_pool.push_back(rid)
	else:
		rid = item_pool[item_pool_index]

	if not rid.is_valid():
		return rid

	if masked:
		masked_items.push_back(rid)

	# setup material properties of new item since something has had to change
	# for this function to be calledd
	_apply_item_parameters(rid)
	return rid


func _apply_item_parameters(rid: RID) -> void:
	item_blend_mode = blend_mode
	item_masker = masker
	item_masked = masked
	item_color_matrix = color_matrix
	item_bounding_box = Rect2()

	RenderingServer.canvas_item_set_draw_behind_parent(rid, false)

	var material := get_material(blend_mode)
	RenderingServer.canvas_item_set_material(
		rid,
		material,
	)

	# for default, sub, and add, you don't need to set the blend_mode as it
	# goes unused & actually doesn't exist anymore to save on instance shader
	# parameters so :p
	if material == _get_other_blends_material():
		RenderingServer.canvas_item_set_instance_shader_parameter(
			rid,
			&"blend_mode",
			int(blend_mode),
		)

	RenderingServer.canvas_item_set_light_mask(rid, light_mask)
	RenderingServer.canvas_item_set_default_texture_filter(rid, texture_filter)
	RenderingServer.canvas_item_set_default_texture_repeat(rid, texture_repeat)

	var needs_backbuffer := blend_needs_backbuffer(blend_mode)
	if needs_backbuffer:
		RenderingServer.canvas_item_set_copy_to_backbuffer(
			rid,
			true,
			get_backbuffer_rect(),
		)

		item_bounding_box = bounding_box

	color_matrix.apply_to_item(rid)

	if masker:
		for masked_rid: RID in masked_items:
			RenderingServer.canvas_item_set_parent(masked_rid, rid)

		RenderingServer.canvas_item_set_material(rid, RID())
		RenderingServer.canvas_item_set_canvas_group_mode(
			rid,
			RenderingServer.CANVAS_GROUP_MODE_CLIP_ONLY,
		)
	else:
		RenderingServer.canvas_item_set_canvas_group_mode(
			rid,
			RenderingServer.CANVAS_GROUP_MODE_DISABLED,
		)


func _get_other_blends_material() -> RID:
	if materials.has(&"other_blends") and is_instance_valid(materials[&"other_blends"]):
		return materials[&"other_blends"].get_rid()
	else:
		return materials[&"default"].get_rid()
