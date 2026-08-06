@tool
class_name TextureAtlasColorMatrix
extends Resource


@export_storage var color_multipliers := Color.WHITE
@export_storage var color_offsets := Vector4.ZERO


static func parse(data: Dictionary, optimized: bool) -> TextureAtlasColorMatrix:
	var matrix := TextureAtlasColorMatrix.new()
	var mode: Variant = data.get("M" if optimized else "mode")

	if mode == null or mode is not String:
		return matrix

	match mode:
		"CA", "Alpha":
			var am: Variant = data.get("AM" if optimized else "alphaMultiplier")
			matrix.color_multipliers.a = float(am)
		"T", "Tint":
			var tc: Variant = data.get("TC" if optimized else "tintColor")
			var tm: Variant = data.get("TM" if optimized else "tintMultiplier")

			var tint_color := Color.from_string(String(tc), Color.WHITE)
			var tint_multiplier := float(tm)
			matrix.color_multipliers.r = 1.0 - tint_multiplier
			matrix.color_multipliers.g = 1.0 - tint_multiplier
			matrix.color_multipliers.b = 1.0 - tint_multiplier
			matrix.color_offsets = Vector4(
				tint_color.r * tint_multiplier,
				tint_color.g * tint_multiplier,
				tint_color.b * tint_multiplier,
				0.0,
			)
		"CBRT", "Brightness":
			var brt: Variant = data.get("BRT" if optimized else "brightness")
			var brightness := float(brt)

			var multiplier := 1.0 - absf(brightness)
			matrix.color_multipliers.r = float(multiplier)
			matrix.color_multipliers.g = float(multiplier)
			matrix.color_multipliers.b = float(multiplier)

			var color_offset := maxf(brightness, 0.0)
			matrix.color_offsets += Vector4(
				color_offset, color_offset, color_offset, 0.0,
			)
		"AD", "Advanced":
			var rm: Variant = data.get("RM" if optimized else "RedMultiplier")
			matrix.color_multipliers.r = float(rm)

			var gm: Variant = data.get("GM" if optimized else "greenMultiplier")
			matrix.color_multipliers.g = float(gm)

			var bm: Variant = data.get("BM" if optimized else "blueMultiplier")
			matrix.color_multipliers.b = float(bm)

			var am: Variant = data.get("AM" if optimized else "alphaMultiplier")
			matrix.color_multipliers.a = float(am)

			var ro: Variant = data.get("RO" if optimized else "redOffset")
			var go: Variant = data.get("GO" if optimized else "greenOffset")
			var bo: Variant = data.get("BO" if optimized else "blueOffset")
			var ao: Variant = data.get("AO" if optimized else "AlphaOffset")
			matrix.color_offsets = Vector4(
				float(ro),
				float(go),
				float(bo),
				float(ao),
			) / 255.0

	return matrix


static func apply_to_other(first: TextureAtlasColorMatrix, second: TextureAtlasColorMatrix) -> TextureAtlasColorMatrix:
	var matrix: TextureAtlasColorMatrix = first.duplicate()
	for i: int in 4:
		if matrix.color_multipliers[i] < 0.0:
			matrix.color_offsets[i] *= 1.0 + matrix.color_multipliers[i]

	var maxed := matrix.color_multipliers
	maxed.r = maxf(maxed.r, 0.0)
	maxed.g = maxf(maxed.g, 0.0)
	maxed.b = maxf(maxed.b, 0.0)
	maxed.a = maxf(maxed.a, 0.0)

	matrix.color_offsets += second.color_offsets * Vector4(maxed.r, maxed.g, maxed.b, maxed.a)
	matrix.color_multipliers = second.color_multipliers * maxed
	return matrix


func apply_to_item(canvas_item: RID) -> void:
	RenderingServer.canvas_item_set_instance_shader_parameter(
		canvas_item,
		&"color_offsets",
		color_offsets,
	)
