const int BLEND_HARD_LIGHT = 5;
const int BLEND_OVERLAY = 11;

vec3 blend_overlay(vec3 base, vec3 blend){
	vec3 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}