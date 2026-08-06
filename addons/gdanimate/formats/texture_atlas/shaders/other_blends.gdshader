shader_type canvas_item;

#include "base.gdshaderinc"

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment() {
	if (blend_mode == BLEND_ALPHA || blend_mode == BLEND_ERASE) {
		discard;
	}

	COLOR = apply_color_matrix(COLOR);

	if (blend_mode != BLEND_NORMAL) {
		vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
		COLOR = apply_blend_mode(COLOR, screen_color);
	}
}