const int BLEND_LIGHTEN = 8;

vec3 blend_lighten(vec3 base, vec3 blend){
	return max(base, blend);
}