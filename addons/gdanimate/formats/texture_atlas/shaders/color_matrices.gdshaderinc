instance uniform vec4 color_offsets = vec4(0.0);

vec4 apply_color_matrix(vec4 color) {
	return color + color_offsets;
}
