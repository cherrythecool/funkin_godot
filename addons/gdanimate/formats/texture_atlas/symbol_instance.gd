@tool
class_name TextureAtlasSymbolInstance
extends TextureAtlasDrawable


@export var key: StringName
@export var type: TextureAtlas.SymbolType
@export var loop_mode: TextureAtlas.SymbolLoopMode
@export var transform: Transform2D
@export var first_frame: int
@export var filters: Array[TextureAtlasFilter] = []
@export var blend_mode: TextureAtlas.BlendMode = TextureAtlas.BlendMode.NORMAL
@export var color_matrix: TextureAtlasColorMatrix = null
@export var symbol: TextureAtlasSymbol = null


static func parse(element: Dictionary, optimized: bool) -> TextureAtlasSymbolInstance:
	element = element.get("SI" if optimized else "SYMBOL_Instance")

	var parsed := TextureAtlasSymbolInstance.new()
	parsed.key = StringName(element.get("SN" if optimized else "SYMBOL_name"))
	parsed.first_frame = element.get("FF" if optimized else "firstFrame", 0)

	if element.has("MX" if optimized else "Matrix"):
		parsed.transform = TextureAtlas.parse_matrix(
			element.get("MX" if optimized else "Matrix"),
		)
	else:
		parsed.transform = TextureAtlas.parse_matrix(
			element.get("M3D" if optimized else "Matrix3D"),
		)

	if element.has("B" if optimized else "blend"):
		parsed.blend_mode = (
			element.get("B" if optimized else "blend")
			as TextureAtlas.BlendMode
		)

	if element.has("C" if optimized else "color"):
		parsed.color_matrix = TextureAtlasColorMatrix.parse(
			element.get("C" if optimized else "color"),
			optimized,
		)

	if element.has("LP" if optimized else "loop"):
		var loop_string: String = element.get("LP" if optimized else "loop")
		match loop_string:
			"playonce", "PO":
				parsed.loop_mode = TextureAtlas.SymbolLoopMode.PLAY_ONCE
			"singleframe", "SF":
				parsed.loop_mode = TextureAtlas.SymbolLoopMode.SINGLE_FRAME
			"loop", "LP", _:
				parsed.loop_mode = TextureAtlas.SymbolLoopMode.LOOP
	else:
		parsed.loop_mode = TextureAtlas.SymbolLoopMode.LOOP

	if element.has("F" if optimized else "filters"):
		var filters: Variant = element.get("F" if optimized else "filters")
		if filters is Array:
			for filter: Dictionary in filters:
				parsed.filters.append(
					TextureAtlasFilter.parse(
						filter.get("N" if optimized else "name"),
						filter,
						optimized
					)
				)
		elif filters is Dictionary:
			for filter_type: String in filters.keys():
				if filters[filter_type] is not Dictionary:
					printerr("Filter type %s not being parsed because it is not a dictionary!" % filter_type)
					continue

				parsed.filters.append(
					TextureAtlasFilter.parse(
						filter_type,
						filters[filter_type] as Dictionary,
						optimized
					)
				)

	var symbol_type: String = element.get("ST" if optimized else "symbolType")
	match symbol_type:
		"movieclip", "MC":
			parsed.type = TextureAtlas.SymbolType.MOVIE_CLIP
		"graphic", "G":
			parsed.type = TextureAtlas.SymbolType.GRAPHIC
		_:
			parsed.type = TextureAtlas.SymbolType.GRAPHIC
			print("Symbol type %s not supported!" % symbol_type)

	return parsed


func draw(target: RID, options: Dictionary = {}) -> void:
	pass


func get_frame_after(amount: int, length: int, movie_clips_play: bool) -> int:
	if type == TextureAtlas.SymbolType.MOVIE_CLIP and movie_clips_play:
		return wrapi(first_frame + amount, 0, length)
	elif type == TextureAtlas.SymbolType.GRAPHIC:
		match loop_mode:
			TextureAtlas.SymbolLoopMode.LOOP:
				return wrapi(first_frame + amount, 0, length)
			TextureAtlas.SymbolLoopMode.PLAY_ONCE:
				return clampi(first_frame + amount, 0, length - 1)
			TextureAtlas.SymbolLoopMode.SINGLE_FRAME:
				return first_frame

	return first_frame
