@tool
class_name TextureAtlasFrame
extends Resource


@export var starting_index: int = 0
@export var duration: int = 0
@export var elements: Array[TextureAtlasDrawable] = []


static func parse(frame: Dictionary, optimized: bool) -> TextureAtlasFrame:
	var parsed := TextureAtlasFrame.new()
	parsed.starting_index = frame.get("I" if optimized else "index")
	parsed.duration = frame.get("DU" if optimized else "duration")

	var elements: Array = frame.get("E" if optimized else "elements", [])
	for element: Dictionary in elements:
		if element == null:
			continue

		if element.has("SI" if optimized else "SYMBOL_Instance"):
			parsed.elements.push_back(
				TextureAtlasSymbolInstance.parse(element, optimized)
			)
		elif element.has("ASI" if optimized else "ATLAS_SPRITE_instance"):
			parsed.elements.push_back(
				TextureAtlasSprite.parse(element, optimized)
			)
		else:
			print("Element not supported! Element keys: %s" % element.keys())

	return parsed
