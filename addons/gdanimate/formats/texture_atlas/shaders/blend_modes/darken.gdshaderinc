const int BLEND_DARKEN = 2;

vec3 blend_darken(vec3 base, vec3 blend){
	return min(base, blend);
}