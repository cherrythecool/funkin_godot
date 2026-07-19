#include "blend_modes/additive.gdshaderinc"
#include "blend_modes/darken.gdshaderinc"
#include "blend_modes/difference.gdshaderinc"
#include "blend_modes/overlay.gdshaderinc"
#include "blend_modes/lighten.gdshaderinc"
#include "blend_modes/multiply.gdshaderinc"
#include "blend_modes/invert.gdshaderinc"
#include "blend_modes/screen.gdshaderinc"
#include "blend_modes/subtract.gdshaderinc"

const int BLEND_ALPHA = 1;
const int BLEND_ERASE = 4;
const int BLEND_NORMAL = 10;

instance uniform vec4 color_offsets = vec4(0.0);

instance uniform int blend_mode : hint_enum(
	"Additive",
	"Alpha",
	"Darken",
	"Difference",
	"Erase",
	"Hard Light",
	"Invert",
	"Layer", // Something something Flash / OpenFL I guess
	"Lighten",
	"Multiply",
	"Normal",
	"Overlay",
	"Screen",
	"Flash Shader", // Maybe if these are exported someone could make a translator? Idk
	"Subtract"
) = 10;

// most from https://godotshaders.com/snippet/blending-modes/
#define __BLEND__(MODE, CALCULATION) if (blend_mode == MODE) {\
	color.rgb = CALCULATION;\
}

vec4 apply_color_matrix(vec4 color) {
	return color + color_offsets;
}

vec4 apply_blend_mode(vec4 color, vec4 screen_color) {
	if (blend_mode != BLEND_NORMAL) {
		__BLEND__(BLEND_ADD, blend_additive(color.rgb, screen_color.rgb))
		__BLEND__(BLEND_DARKEN, blend_darken(color.rgb, screen_color.rgb))
		__BLEND__(BLEND_DIFFERENCE, blend_difference(color.rgb, screen_color.rgb))
		__BLEND__(BLEND_HARD_LIGHT, blend_overlay(color.rgb, screen_color.rgb))
		__BLEND__(BLEND_INVERT, blend_invert(screen_color.rgb))
		__BLEND__(BLEND_LIGHTEN, blend_lighten(color.rgb, screen_color.rgb))
		__BLEND__(BLEND_MULTIPLY, blend_multiply(color.rgb, screen_color.rgb))
		__BLEND__(BLEND_OVERLAY, blend_overlay(screen_color.rgb, color.rgb))
		__BLEND__(BLEND_SCREEN, blend_screen(color.rgb, screen_color.rgb))
		__BLEND__(BLEND_SUBTRACT, blend_subtract(screen_color.rgb, color.rgb))
	}

	return color;
}