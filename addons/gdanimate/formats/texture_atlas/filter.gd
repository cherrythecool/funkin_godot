class_name TextureAtlasFilter
extends Resource


enum FilterType {
	UNKNOWN = 0,
	BLUR,
	ADJUST_COLOR,
	DROP_SHADOW,
	GLOW,
	BEVEL,

	# TODO: later because these aren't even implemented in
	# flixel-animate :sob:
	GRADIENT_BEVEL,
	GRADIENT_GLOW,
}

@export var type: FilterType = FilterType.UNKNOWN
@export var data: Dictionary[StringName, Variant]


static func parse(
	filter_type: String,
	json: Dictionary,
	optimized: bool
) -> TextureAtlasFilter:
	var filter := TextureAtlasFilter.new()
	match filter_type:
		"blurFilter", "BLF":
			filter.type = FilterType.BLUR
		"adjustColorFilter", "ACF":
			filter.type = FilterType.ADJUST_COLOR
		"dropShadowFilter", "DSF":
			filter.type = FilterType.DROP_SHADOW
		"glowFilter", "GF":
			filter.type = FilterType.GLOW
		"bevelFilter", "BF":
			filter.type = FilterType.BEVEL
		"gradientBevelFilter", "GBF":
			filter.type = FilterType.GRADIENT_BEVEL
		"gradientGlowFilter", "GGF":
			filter.type = FilterType.GRADIENT_GLOW
		_:
			filter.type = FilterType.UNKNOWN

	match filter.type:
		FilterType.BLUR:
			filter.data = {
				&"x": json.get("BLX" if optimized else "blurX", 0.0),
				&"y": json.get("BLY" if optimized else "blurY", 0.0),
				&"quality": json.get("Q" if optimized else "quality", 1),
			}
		_:
			print("Filter type %s not supported." % filter_type)

	return filter
