shader_type canvas_item;

#include "color_matrices.gdshaderinc"

void fragment() {
	COLOR = apply_color_matrix(COLOR);
}