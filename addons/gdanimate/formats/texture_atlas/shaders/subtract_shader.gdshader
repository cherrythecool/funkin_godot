shader_type canvas_item;
render_mode blend_sub;

#include "color_matrices.gdshaderinc"

void fragment() {
	COLOR = apply_color_matrix(COLOR);
}