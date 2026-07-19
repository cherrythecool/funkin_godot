@tool
class_name TextureAtlasSymbol
extends Resource


@export var layers: Array[TextureAtlasLayer] = []
@export var layers_draw_order: Array = []
@export var length: int = 0


static func parse(symbol: Dictionary, optimized: bool) -> TextureAtlasSymbol:
	var parsed_symbol := TextureAtlasSymbol.new()
	var layers: Array = []

	if symbol.has("TL" if optimized else "TIMELINE"):
		var timeline: Dictionary = symbol.get("TL" if optimized else "TIMELINE", {})
		layers = timeline.get("L" if optimized else "LAYERS", [])
	elif symbol.has("L" if optimized else "LAYERS"):
		layers = symbol.get("L" if optimized else "LAYERS", [])

	for layer: Dictionary in layers:
		var parsed_layer := TextureAtlasLayer.parse(layer, optimized)
		if parsed_symbol.length < parsed_layer.start_index + parsed_layer.duration:
			parsed_symbol.length = parsed_layer.start_index + parsed_layer.duration

		parsed_symbol.layers.push_back(parsed_layer)

	parsed_symbol.layers_draw_order = range(parsed_symbol.layers.size() - 1, -1, -1)
	return parsed_symbol
