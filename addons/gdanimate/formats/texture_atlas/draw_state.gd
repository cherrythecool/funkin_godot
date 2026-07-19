@tool
class_name TextureAtlasDrawState
extends RefCounted


var item_pool: Array[RID]
var item_pool_index: int = 0

var texture_filter: RenderingServer.CanvasItemTextureFilter

var materials: Dictionary[StringName, Material] = {}

var backbuffer_transform := Transform2D.IDENTITY
var local_transform := Transform2D.IDENTITY

var blend_mode := TextureAtlas.BlendMode.NORMAL
var item_blend_mode := TextureAtlas.BlendMode.NORMAL

var color_matrix := TextureAtlasColorMatrix.new()
var item_color_matrix := color_matrix

var masked := false
var item_masked := false
var masked_items: Array[RID]

var masker := false
var item_masker := false


func apply_material_to_current() -> void:
	var current_item := get_current_item()
	RenderingServer.canvas_item_set_material(
		current_item,
		get_material(blend_mode),
	)

	RenderingServer.canvas_item_set_instance_shader_parameter(
		current_item,
		&"blend_mode",
		int(blend_mode),
	)


func blend_needs_backbuffer(blend: TextureAtlas.BlendMode) -> bool:
	match blend:
		TextureAtlas.BlendMode.SUBTRACT:
			return not (materials.has(&"blend_subtract") and is_instance_valid(materials[&"blend_subtract"]))
		TextureAtlas.BlendMode.ADD:
			return not (materials.has(&"blend_add") and is_instance_valid(materials[&"blend_add"]))
		TextureAtlas.BlendMode.NORMAL, _:
			return true


func get_material(blend: TextureAtlas.BlendMode) -> RID:
	match blend:
		TextureAtlas.BlendMode.SUBTRACT:
			if materials.has(&"blend_subtract") and is_instance_valid(materials[&"blend_subtract"]):
				return materials[&"blend_subtract"].get_rid()
			else:
				return _get_other_blends_material()
		TextureAtlas.BlendMode.ADD:
			if materials.has(&"blend_add") and is_instance_valid(materials[&"blend_add"]):
				return materials[&"blend_add"].get_rid()
			else:
				return _get_other_blends_material()
		TextureAtlas.BlendMode.NORMAL:
			return materials[&"default"].get_rid()
		_:
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

	if masked:
		masked_items.push_back(rid)

	RenderingServer.canvas_item_set_default_texture_filter(
		rid,
		texture_filter,
	)
	RenderingServer.canvas_item_set_default_texture_repeat(
		rid,
		RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_DISABLED,
	)

	return rid


func _get_other_blends_material() -> RID:
	if materials.has(&"other_blends") and is_instance_valid(materials[&"other_blends"]):
		return materials[&"other_blends"].get_rid()
	else:
		return materials[&"default"].get_rid()
