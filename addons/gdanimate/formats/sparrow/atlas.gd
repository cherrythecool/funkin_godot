@tool
class_name SparrowAtlas
extends AnimateSymbolLibrary


@export_file_path("*.xml") var source_path: String:
	set(v):
		source_path = v
		parse()
		path_changed.emit()

@export var texture: Texture2D:
	set(v):
		texture = v
		redraw_requested.emit()

@export var override_texture := false

@export_range(0.0, 100.0, 0.01, "or_greater") var framerate: float = 24.0
@export_tool_button("Export", "SpriteFrames") var export_spriteframes := export

@export_storage var frames: Array[SparrowFrame]
@export_storage var symbols: PackedStringArray

# Caches the relationship between symbols -> frames
# so that there is less time needed to filter the
# frames array every frame
var _internal_frames_cache: Dictionary[String, Array]

# Yes I really got to this point of optimization. I'm not kidding.
# (And it really does help performance a LITTLE).
var _internal_bounding_cache: Dictionary[String, Rect2]


func parse() -> void:
	has_symbols_with_commas = false
	frames.clear()
	symbols.clear()
	_internal_frames_cache.clear()
	_internal_bounding_cache.clear()

	var basename: String = source_path.get_basename()
	var cache_path: String = "%s.res" % [basename]
	if ResourceLoader.exists(cache_path):
		var cached: SparrowAtlas = load(cache_path)
		framerate = cached.framerate
		frames = cached.frames
		texture = cached.texture
		symbols = cached.symbols
		check_symbols_have_commas(symbols)
		symbols_changed.emit()
		return

	if not FileAccess.file_exists(source_path):
		printerr("Failed to find sparrow at path \"%s\"!" % [source_path])
		symbols_changed.emit()
		return

	var xml := XMLParser.new()
	var open_error: Error = xml.open(source_path)
	if open_error != OK:
		printerr("Failed to open XML, error code: %s!" % [open_error])
		symbols_changed.emit()
		return

	while xml.read() != ERR_FILE_EOF:
		if xml.get_node_type() != XMLParser.NODE_ELEMENT:
			continue

		var node_name: String = xml.get_node_name().to_lower()
		match node_name:
			"textureatlas":
				if override_texture:
					continue
				var path: String = "%s/%s" % [
					source_path.get_base_dir(),
					xml.get_named_attribute_value_safe("imagePath"),
				]

				if not ResourceLoader.exists(path):
					path = "%s.png" % [basename]
				if ResourceLoader.exists(path):
					texture = load(ResourceUID.path_to_uid(path))
			"subtexture":
				var frame: SparrowFrame = SparrowFrame.new()
				frame.parse(xml)
				frames.push_back(frame)

	frames.sort_custom(SparrowFrame.sort_by_name)

	for frame: SparrowFrame in frames:
		var array: Array[Variant] = frame.get_name_array()
		if array.size() < 2:
			continue
		if not symbols.has(array[0]):
			symbols.push_back(array[0])

	check_symbols_have_commas(symbols)
	symbols_changed.emit()


func cache() -> void:
	var resource_path: String = "%s.res" % [source_path.get_basename()]
	take_over_path(resource_path)
	ResourceSaver.save(
		self,
		resource_path,
		(
			ResourceSaver.FLAG_COMPRESS +
			ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS
		),
	)


func draw_2d(target: AnimateSymbol2D) -> void:
	target._clear_canvas_item(true)

	var sparrow_frame: SparrowFrame = SparrowFrame.get_filtered_frame(
		target.symbol,
		target.frame,
		self,
	)

	if not is_instance_valid(sparrow_frame):
		return

	var canvas_item: RID = target.get_canvas_item()
	var offset: Vector2 = target.offset
	if target.centered:
		offset -= get_symbol_rect(target.symbol).size / 2.0

	sparrow_frame.draw_2d(canvas_item, texture, offset)


func get_framerate() -> float:
	return framerate


func get_filename() -> StringName:
	return StringName(source_path.get_file())


func get_symbol_list() -> PackedStringArray:
	return symbols


func get_symbol_length(key: StringName) -> int:
	if not _internal_frames_cache.has(key):
		_internal_frames_cache[key] = SparrowFrame.get_filtered_frames(key, self)

	return maxi(_internal_frames_cache[key].size() - 1, 0)


func has_symbol(symbol: StringName) -> bool:
	return symbols.has(String(symbol))


func get_symbol_rect(symbol: StringName) -> Rect2:
	if not _internal_bounding_cache.has(symbol):
		var filtered: Array[SparrowFrame] = SparrowFrame.get_filtered_frames(
			symbol,
			self,
		)

		var bounding := Rect2()
		for frame: SparrowFrame in filtered:
			bounding = bounding.merge(frame.get_bounding_box())

		_internal_bounding_cache[symbol] = bounding

	return _internal_bounding_cache[symbol]


func export() -> void:
	SparrowAtlasExporter.export(self)
