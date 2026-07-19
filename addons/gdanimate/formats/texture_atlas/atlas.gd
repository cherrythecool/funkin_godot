@tool
class_name TextureAtlas
extends AnimateSymbolLibrary


enum BlendMode {
	ADD = 0,
	ALPHA = 1,
	DARKEN = 2,
	DIFFERENCE = 3,
	ERASE = 4,
	HARD_LIGHT = 5,
	INVERT = 6,
	LAYER = 7,
	LIGHTEN = 8,
	MULTIPLY = 9,
	NORMAL = 10,
	OVERLAY = 11,
	SCREEN = 12,
	SHADER = 13,
	SUBTRACT = 14,
}

enum SymbolType {
	GRAPHIC = 0,
	MOVIE_CLIP
	# TODO: BUTTONs
}

enum SymbolLoopMode {
	LOOP = 0,
	PLAY_ONCE,
	SINGLE_FRAME,
	REVERSE_PLAY_ONCE, # TODO: Implement
	REVERSE_LOOP # TODO: Implement
}

const MATERIAL_LIST: Array[StringName] = [
	&"default",
	&"blend_add",
	&"blend_subtract",
	&"other_blends",
]

## Path to any file in the animation path (like Animation.json, spritemap1.json, etc),
## or the folder that contains those files.
@export_dir var folder: String = "":
	set(v):
		if folder != v:
			folder = v

			if not folder.get_extension().is_empty():
				folder = folder.get_base_dir()
			elif folder.ends_with("/"):
				folder = folder.left(-1)

			parse()
			path_changed.emit()

# TODO: fix the impl for this
## For movie clips to play more like in a SWF, set to true.
@export var movie_clips_play: bool = false:
	set(v):
		if movie_clips_play != v:
			movie_clips_play = v
			redraw_requested.emit()

## Clips the edges outside of each part of the spritemap (to help prevent edge bleeding, may not always be desired)
@export var clip_texture_uvs: bool = false:
	set(v):
		if clip_texture_uvs != v:
			clip_texture_uvs = v
			redraw_requested.emit()

## Uses a simpler form of rendering the atlas that takes less time but doesn't support
## more "advanced" features like Blend Modes, Masking, etc.[br][br]
## Use if you need better performance (usually with a lot of TAs at once)
## and don't need those more complex features.
@export_enum("Full", "Performance") var render_mode: String = "Full":
	set(v):
		if render_mode != v:
			render_mode = v
			redraw_requested.emit()
			notify_property_list_changed()

## Override internal default materials used by [TextureAtlas]
var override_enable := false:
	set(v):
		if override_enable != v:
			override_enable = v
			redraw_requested.emit()

var override_default: Material = null:
	set(v):
		if override_default != v:
			override_default = v
			redraw_requested.emit()

var override_blend_add: Material = null:
	set(v):
		if override_blend_add != v:
			override_blend_add = v
			redraw_requested.emit()

var override_blend_subtract: Material = null:
	set(v):
		if override_blend_subtract != v:
			override_blend_subtract = v
			redraw_requested.emit()

var override_other_blends: Material = null:
	set(v):
		if override_other_blends != v:
			override_other_blends = v
			redraw_requested.emit()

var spritemap: Dictionary[StringName, AtlasTexture] = {}
var symbols: Dictionary[StringName, TextureAtlasSymbol] = {}
var framerate: float = 24.0
var stage_symbol: StringName = &""
var stage_transform: Transform2D = Transform2D.IDENTITY

var _internal_materials: Dictionary[StringName, Material]


static func parse_matrix(matrix: Variant) -> Transform2D:
	if matrix is Dictionary:
		return Transform2D(
			Vector2(matrix["m00"], matrix["m01"]),
			Vector2(matrix["m10"], matrix["m11"]),
			Vector2(matrix["m30"], matrix["m31"]),
		)
	elif matrix is Array:
		if matrix.size() == 6:
			return Transform2D(
				Vector2(matrix[0], matrix[1]),
				Vector2(matrix[2], matrix[3]),
				Vector2(matrix[4], matrix[5]),
			)
		else:
			return Transform2D(
				Vector2(matrix[0], matrix[1]),
				Vector2(matrix[4], matrix[5]),
				Vector2(matrix[12], matrix[13]),
			)
	else:
		return Transform2D.IDENTITY


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	if Engine.is_editor_hint() and render_mode == "Full":
		properties.push_back({
			"name": &"Rendering Options",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
		})

		properties.push_back({
			"name": &"Override Materials",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_SUBGROUP,
			"hint_string": "override_",
		})

		properties.push_back({
			"name": &"override_enable",
			"type": TYPE_BOOL,
			"hint": PROPERTY_HINT_GROUP_ENABLE,
			"usage": PROPERTY_USAGE_DEFAULT,
		})

		for name: StringName in MATERIAL_LIST:
			properties.push_back({
				"name": &"override_%s" % name,
				"type": TYPE_OBJECT,
				"usage": PROPERTY_USAGE_DEFAULT,
			})

	return properties


func parse() -> void:
	redraw_requested.emit()

	var cache_path := "%s/animation_cache.res" % [folder]
	if ResourceLoader.exists(cache_path):
		var cached: TextureAtlasCache = load(cache_path)
		if is_instance_valid(cached):
			cached.apply_to_atlas(self)
			return

	symbols.clear()
	spritemap.clear()

	var animation_json := "%s/Animation.json" % [folder]
	if not ResourceLoader.exists(animation_json):
		printerr("Atlas path (%s) is missing Animation.json!" % [folder])
		return

	TextureAtlasSpritemap.load_spritemaps(folder, spritemap)
	load_animation()


func cache() -> void:
	TextureAtlasCache.save_from_atlas(self)


func draw_2d(target: AnimateSymbol2D) -> void:
	var symbol: StringName = target.symbol
	var use_stage: bool = not symbols.has(target.symbol)
	if use_stage and not stage_symbol.is_empty():
		symbol = stage_symbol

	if not symbols.has(symbol):
		return

	var transform := Transform2D(0.0, target.offset)
	if target.centered:
		var rect: Rect2 = get_symbol_rect(symbol)
		transform = transform.translated(
			-rect.position - (rect.size / 2.0),
		)

	if use_stage:
		transform *= stage_transform

	var target_item := target.get_canvas_item()
	match render_mode:
		"Performance":
			target._clear_canvas_item(true)
			_internal_materials.clear()
			draw_2d_simple(
				symbols[symbol],
				target.frame,
				transform,
				target_item,
			)
		"Full":
			if _internal_materials.is_empty():
				_internal_materials = {
					&"default": load("res://addons/gdanimate/formats/texture_atlas/shaders/sprite_material.tres"),
					&"blend_add": load("res://addons/gdanimate/formats/texture_atlas/shaders/additive_material.tres"),
					&"blend_subtract": load("res://addons/gdanimate/formats/texture_atlas/shaders/subtract_material.tres"),
				}

			var state := TextureAtlasDrawState.new()
			state.item_pool = target._canvas_item_pool
			state.materials = _internal_materials.duplicate()
			state.texture_filter = target.texture_filter as RenderingServer.CanvasItemTextureFilter

			if is_instance_valid(target.material):
				state.materials[&"default"] = target.material

			if override_enable:
				for name: StringName in MATERIAL_LIST:
					var material := get(&"override_%s" % name)
					if is_instance_valid(material):
						state.materials[name] = material

			target._clear_canvas_item(false)
			target._reset_canvas_item_pool()

			var root_item: RID = state.get_next_item()
			RenderingServer.canvas_item_set_parent(
				root_item,
				target_item,
			)

			RenderingServer.canvas_item_set_transform(root_item, transform)
			RenderingServer.canvas_item_set_default_texture_filter(
				root_item,
				state.texture_filter,
			)

			RenderingServer.canvas_item_set_default_texture_repeat(
				root_item,
				RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_DISABLED,
			)

			state.apply_material_to_current()

			draw_2d_full(
				symbols[symbol],
				target.frame,
				state,
				root_item,
			)


func draw_2d_simple(
	symbol: TextureAtlasSymbol,
	frame: int,
	transform: Transform2D,
	target: RID,
) -> void:
	for i: int in symbol.layers_draw_order:
		var layer := symbol.layers[i]
		if not frame in layer.frame_range:
			continue
		if not layer.frame_indexes.has(frame):
			continue

		var layer_frame := layer.frames[layer.frame_indexes[frame]]
		for element: TextureAtlasDrawable in layer_frame.elements:
			if element is TextureAtlasSprite:
				var texture := spritemap[element.key]
				texture.filter_clip = clip_texture_uvs
				element.draw(target, {
					&"texture": texture,
					&"transform": transform,
					&"modulate": Color.WHITE,
				})
			elif element is TextureAtlasSymbolInstance:
				draw_2d_simple(symbols[element.key],
					element.get_frame_after(
						frame - layer_frame.starting_index,
						symbols[element.key].length,
						movie_clips_play,
					),
					transform * element.transform,
					target,
				)


func draw_2d_full(
	symbol: TextureAtlasSymbol,
	frame: int,
	state: TextureAtlasDrawState,
	target: RID,
) -> void:
	var start_transform := state.local_transform
	var start_blend := state.blend_mode
	var start_color_matrix := state.color_matrix

	for i: int in symbol.layers_draw_order:
		var layer := symbol.layers[i]
		if not frame in layer.frame_range:
			continue
		if not layer.frame_indexes.has(frame):
			continue

		if not layer.clipped_by.is_empty():
			state.masked = true

		if layer.clipping:
			state.masker = true

		var layer_frame := layer.frames[layer.frame_indexes[frame]]
		var current_item: RID
		for element: TextureAtlasDrawable in layer_frame.elements:
			current_item = state.get_current_item()

			state.blend_mode = start_blend
			state.color_matrix = start_color_matrix
			state.local_transform = start_transform

			if element is TextureAtlasSprite:
				if (
					state.item_masker != state.masker or
					state.item_masked != state.masked or
					state.item_blend_mode != state.blend_mode or
					state.item_color_matrix.color_offsets != state.color_matrix.color_offsets
				):
					current_item = state.get_next_item()
					RenderingServer.canvas_item_set_parent(current_item, target)

					state.item_masker = state.masker
					state.item_masked = state.masked
					state.item_blend_mode = state.blend_mode
					state.item_color_matrix = state.color_matrix
					state.apply_material_to_current()
					state.color_matrix.apply_to_item(current_item)

					if state.masker:
						for rid: RID in state.masked_items:
							RenderingServer.canvas_item_set_parent(rid, current_item)

						RenderingServer.canvas_item_set_material(current_item, RID())
						RenderingServer.canvas_item_set_canvas_group_mode(
							current_item,
							RenderingServer.CANVAS_GROUP_MODE_CLIP_ONLY,
						)
					else:
						RenderingServer.canvas_item_set_canvas_group_mode(
							current_item,
							RenderingServer.CANVAS_GROUP_MODE_DISABLED,
						)

					if state.blend_needs_backbuffer(state.blend_mode):
						# TODO: calculate bounding boxes for optimized copying
						RenderingServer.canvas_item_set_copy_to_backbuffer(
							current_item,
							true,
							Rect2(),
						)

				var texture := spritemap[element.key]
				texture.filter_clip = clip_texture_uvs
				element.draw(current_item, {
					&"texture": texture,
					&"transform": state.local_transform,
					&"modulate": Color(
						state.color_matrix.color_multipliers.x,
						state.color_matrix.color_multipliers.y,
						state.color_matrix.color_multipliers.z,
						state.color_matrix.color_multipliers.w,
					),
				})
			elif element is TextureAtlasSymbolInstance:
				state.local_transform *= element.transform

				if element.color_matrix:
					state.color_matrix = TextureAtlasColorMatrix.apply_to_other(
						state.color_matrix,
						element.color_matrix
					)

				if (
					start_blend == BlendMode.NORMAL and
					state.blend_mode != element.blend_mode
				):
					state.blend_mode = element.blend_mode

				draw_2d_full(symbols[element.key],
					element.get_frame_after(
						frame - layer_frame.starting_index,
						symbols[element.key].length,
						movie_clips_play,
					),
					state,
					target,
				)

		if not layer.clipped_by.is_empty():
			state.masked = false

		if layer.clipping:
			state.masked_items.clear()
			state.masker = false


func get_framerate() -> float:
	return framerate


func get_filename() -> StringName:
	return StringName(folder.get_file())


func get_symbol_list() -> PackedStringArray:
	return symbols.keys()


func get_symbol_length(key: StringName) -> int:
	if not symbols.has(key):
		key = stage_symbol
	if symbols.has(key):
		return symbols[key].length

	return 0


func get_symbol_rect(key: StringName) -> Rect2:
	if not symbols.has(key):
		return Rect2()

	#return symbols[key].bounding_box
	return Rect2()


func has_symbol(symbol: StringName) -> bool:
	return symbols.has(symbol)


func load_animation() -> void:
	var raw_json: String = FileAccess.get_file_as_string("%s/Animation.json" % [folder])
	var json: Variant = JSON.parse_string(raw_json)
	if json == null:
		printerr("Failed to parse %s/Animation.json as JSON!" % folder)
		return

	if json is not Dictionary:
		printerr("Animation JSON must be a Dictionary!")
		return

	json = json as Dictionary

	var optimized: bool = json.has("AN")
	if ResourceLoader.exists("%s/metadata.json" % folder):
		var meta_raw_json: String = FileAccess.get_file_as_string("%s/metadata.json" % [folder])
		var meta_json: Variant = JSON.parse_string(meta_raw_json)
		if meta_json == null:
			printerr("Failed to parse %s/metadata.json as JSON!" % folder)
			return

		if meta_json is not Dictionary:
			print("Metadata JSON must be a Dictionary!")
			return

		meta_json = meta_json as Dictionary
		framerate = meta_json.get("framerate", meta_json.get("FRT", 24.0))
	else:
		var meta: Dictionary = json.get("MD" if optimized else "metadata", {})
		framerate = meta.get("FRT" if optimized else "framerate", 24.0)

	if json.has("SD" if optimized else "SYMBOL_DICTIONARY"):
		var symbol_dict: Dictionary = json.get("SD" if optimized else "SYMBOL_DICTIONARY", {})
		var symbol_array: Array = symbol_dict.get("S" if optimized else "Symbols", [])
		SymbolDictionary.parse_array(symbol_array, optimized, symbols)
	elif DirAccess.dir_exists_absolute("%s/LIBRARY" % folder):
		var dir: DirAccess = DirAccess.open("%s/LIBRARY" % folder)
		if dir == null:
			printerr("Failed to open %s/LIBRARY directory! Error: " % [
				folder,
				DirAccess.get_open_error(),
			])

			return

		SymbolDictionary.load_symbols_directory(
			optimized,
			dir,
			"",
			symbols,
		)

	var main_animation: Dictionary = json.get("AN" if optimized else "ANIMATION", {})
	SymbolDictionary.parse_symbol(main_animation, optimized, symbols)

	stage_symbol = main_animation.get("SN" if optimized else "SYMBOL_name")
	stage_transform = Transform2D.IDENTITY

	if main_animation.has("STI" if optimized else "StageInstance"):
		var stage: Dictionary = main_animation.get("STI" if optimized else "StageInstance", {})
		var instance: Dictionary = stage.get("SI" if optimized else "SYMBOL_Instance", {})

		if instance.has("MX" if optimized else "Matrix"):
			stage_transform = parse_matrix(instance.get("MX" if optimized else "Matrix"))
		elif instance.has("M3D" if optimized else "Matrix3D"):
			stage_transform = parse_matrix(instance.get("M3D" if optimized else "Matrix3D"))
