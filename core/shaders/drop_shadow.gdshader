shader_type canvas_item;
//Rimlight / Drop shadow BY MABLE / MAE / MABLE YEAH
//hi :p

varying vec4 modulate;

group_uniforms general_config;

//0.25 or 0.8 me likey
uniform float blur_strength : hint_range(0.0,5.0,0.01) = 0.25;

group_uniforms DropShadow_general;
uniform float inline_scale :hint_range(1.0,2.0) = 1.0;
uniform float strength : hint_range(0.0,1.5) = 1.0;
uniform float rim_mix : hint_range(-10.0, 3.0, 0.1) = 2.0;
uniform bool affect_black = false;
uniform bool pixel_perfect = false;



group_uniforms DropShadow_general.specifics;
uniform vec3 shadow_color : source_color = vec3(0.5);
uniform vec3 shadow_color_2 : source_color = vec3(0.0);
uniform float angle : hint_range(-360, 360,0.1) = 0.0;
uniform float angle_2 : hint_range(-360, 360,0.1) = 0.0;
uniform float dist :  hint_range(0.0,50.0,0.1) = 0.0;
uniform float dist_2 :  hint_range(0.0,50.0,0.1) = 0.0;

//Priority makes the shadows stop at their meeting points rather than overlapping, MOSTLY
uniform int blend_mode : hint_enum("None","PRIORITY") = 1;


group_uniforms HSBC_config;
uniform float hue :hint_range(-300, 300) = 0;
uniform float saturation  :hint_range(-100, 500) = 0;
uniform float brightness  :hint_range(-280, 280) = 0;
uniform float contrast  :hint_range(-500, 500) = 0;
uniform float alpha  :hint_range(0, 1) = 1;

//just kinda took both of these color related functions from FNF
vec3 applyHue(vec3 aColor, float aHue) {
	float angle_ = radians(aHue);
	vec3 k = vec3(0.57735, 0.57735, 0.57735);
	float cosAngle = cos(angle_);
	return aColor * cosAngle + cross(k, aColor) * sin(angle_) + k * dot(k, aColor) * (1.0 - cosAngle);
}

vec3 applyHSBCEffect(vec3 color) {
	color = clamp(color + ((brightness) / 255.0), 0.0, 1.0);
	color = applyHue(color, hue);
	color = clamp((color - 0.5) * (1.0 + ((contrast) / 255.0)) + 0.5, 0.0, 1.0);

	vec3 intensity = vec3(dot(color, vec3(0.30980392156, 0.60784313725, 0.08235294117)));
	color = clamp(mix(intensity, color, (1.0 + (saturation / 100.0))), 0.0, 1.0);
	return color;
}

//does what it says on the tin, also applies a bit of fade
float clamp_uv(vec2 uv, float _alpha) {
	float edge_softness = 0.05 * blur_strength;
	float fade_x = smoothstep(0.0, edge_softness, uv.x) * (1.0 - smoothstep(1.0 - edge_softness, 1.0, uv.x));
	float fade_y = smoothstep(0.0, edge_softness, uv.y) * (1.0 - smoothstep(1.0 - edge_softness, 1.0, uv.y));
	float fade = fade_x * fade_y;
	return _alpha * fade;
}

vec2 clamp_region(vec2 uv, vec4 region) {
	vec2 min_uv = region.xy;
	vec2 max_uv = vec2(1.0);
	if (region.z > 0.0) {
		max_uv.x = min_uv.x + region.z;
	}
	if (region.w > 0.0) {
		max_uv.y = min_uv.y + region.w;
	}

	return clamp(uv, min_uv, max_uv);
}

// taken from https://github.com/godotengine/godot/pull/90436#issuecomment-2776191472
// we need to do this because a lot of math relies on the UVs being
// in 0.0 - 1.0 scale like a normal texture, but we're working with regions (not 0.0-1.0)
// so scale_in will scale it to 0.0-1.0
// and scale_out will scale it back to normal (which can be sampled with texture())
vec2 scale_uv_in(vec2 uv, vec4 region) {
	uv -= region.xy;
	if (abs(region.z) > 0.0001) {
		uv.x /= region.z;
	}

	if (abs(region.w) > 0.0001) {
		uv.y /= region.w;
	}

	return uv;
}

vec2 scale_uv_out(vec2 uv, vec4 region) {
	if (abs(region.z) < 0.0001) {
		region.z = 1.0;
	}

	if (abs(region.w) < 0.0001) {
		region.w = 1.0;
	}

	return (uv * region.zw) + region.xy;
}

//based on /https://www.shadertoy.com/view/Xltfzj and https://xorshaders.weebly.com/tutorials/blur-shaders-5-part-2
vec4 blur_b(sampler2D Texture, vec2 uv, float val, vec4 region){
	float Pi = PI * 2.0;
	vec2 tex_size = vec2(textureSize(Texture,0));
	vec2 Texture_pixel_size = 1.0 / tex_size;
	float Directions = 12.0;
	float Quality = 6.0;
	float Size = 8.0 * val;

	vec2 radius = Size/Texture_pixel_size.xy;
	if (abs(region.z) > 0.0001) {
		radius.x *= region.z;
	}
	if (abs(region.w) > 0.0001) {
		radius.y *= region.w;
	}

	vec4 Color = texture(Texture,uv);
	for(float d = 0.0; d < Pi; d += Pi / float(Directions)) {
		for(float i = 1.0 / float(Quality); i <= 1.0; i += 1.0 / float(Quality)) {
			vec2 this_uv = uv;
			this_uv = scale_uv_in(this_uv, region);
			this_uv += vec2(cos(d), sin(d)) * radius * i;
			this_uv = scale_uv_out(this_uv, region);
			this_uv = clamp_region(this_uv, region);

			Color += texture(Texture, this_uv);
		}
	}

	Color /= float(Quality) * float(Directions) + 1.0;
	Color.rgb = applyHSBCEffect(Color.rgb);
	return Color;
}


//Inspired by FNF's drop shadow shader, but ultimately re-made from scratch to be in one function so i could add two
vec3 dropShadow(sampler2D Texture, vec2 Uv, float ang, float shadow_dist, vec4 region) {
	vec2 texture_size = 1.0 / vec2(textureSize(Texture, 0));
	vec2 uv = Uv;
	uv = scale_uv_in(uv, region);

	if (pixel_perfect) {
		uv = floor(uv / texture_size + 0.5) * texture_size;
	}

	mat2 scale = mat2(vec2(inline_scale + (blur_strength/100.0), 0.0), vec2(0.0, inline_scale + (blur_strength/100.0)));
	uv -= 0.5;
	vec2 rotation = vec2(cos(-ang / 100.0), sin(-ang / 100.0));
	uv = uv * scale;
	uv += 0.5;
	uv = scale_uv_out(uv, region);

	uv += (rotation * texture_size) * shadow_dist;
	// TODO: This line breaks some sprites, but I forget if it causes
	// any issues not being here anymore. If you find an issue, maybe
	// look into this line I guess.
	//uv = clamp_region(uv, region);

	////DOES move
	vec4 inner = blur_b(Texture,uv,abs(sin(blur_strength * .00001)),region);
	inner.rgb = vec3(0.0);
	uv = scale_uv_in(uv, region);
	inner.a = clamp_uv(uv,inner.a);

	//essentially inner cuts out a piece of this and then that gets pasted over the final image
	vec4 shadow = texture(Texture,Uv);
	shadow.rgb = vec3(1.0);

	float blend = smoothstep(1.65 ,rim_mix - 1.15, inner.a  / 0.5);
	vec3 shadow_blend = mix(inner, shadow, blend).rgb;
	return (shadow_blend * strength);
}


vec3 mix_shadow_and_base(vec3 base,vec3 blend){
	float factor = affect_black ? 1.0 : smoothstep(0.05, 0.5, length(base));
	return mix(base, base + blend, factor);
}

//passes both shadows in and returns either the original or a "prioritized" shadow pass
//where both shadows don't collide as much
vec3 apply_mode(vec3 bg, vec3 src,int blendMode) {
	if (blendMode == 0){
		return bg;
	}

	float feather_size = 0.5;
	vec3 Luminance = vec3(0.2126, 0.7152, 0.0722);
    float src_lum = dot(src,Luminance);
    float bg_lum = dot(bg, Luminance);

    float low  = bg_lum - feather_size;
    float high = bg_lum + feather_size;
    float feather = smoothstep(low, high, src_lum);
    return mix(bg, vec3(0.0), feather);
}

void vertex(){
	modulate = COLOR;
}

void fragment() {
	COLOR.rgb = applyHSBCEffect(COLOR.rgb);

	if (abs(inline_scale) > 1.0 || abs(dist + dist_2) > 0.0001) {
		vec3 rimlight = dropShadow(TEXTURE,UV,angle,dist,REGION_RECT);
		vec3 rimlight_2 = dropShadow(TEXTURE,UV,-angle_2,-dist_2,REGION_RECT) * shadow_color_2;

		rimlight_2 = apply_mode(rimlight_2,rimlight,blend_mode);
		rimlight = apply_mode(rimlight,rimlight_2,blend_mode);

		rimlight *= shadow_color;
		rimlight_2 *= shadow_color_2;

		COLOR.rgb = mix_shadow_and_base(COLOR.rgb,rimlight_2);
		COLOR.rgb = mix_shadow_and_base(COLOR.rgb,rimlight);
	}

	// a semi decent compromise to blur the entire thing whilst also having drop shadows/ rim lighting
	if (!pixel_perfect) {
		COLOR = mix(COLOR,
			blur_b(TEXTURE, UV, abs(sin(blur_strength / 10.0 * 0.00001)),REGION_RECT),
			blur_strength / 5.0
		);
	}

	COLOR.a *= alpha;
	COLOR *= modulate;
}