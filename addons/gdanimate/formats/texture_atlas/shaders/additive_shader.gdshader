shader_type canvas_item;
render_mode blend_add;

#include "base.gdshaderinc"

void fragment() {
	if (blend_mode == BLEND_ALPHA || blend_mode == BLEND_ERASE) {
		discard;
	}

	COLOR = apply_color_matrix(COLOR);
}