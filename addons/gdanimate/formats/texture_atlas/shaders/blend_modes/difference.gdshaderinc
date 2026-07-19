const int BLEND_DIFFERENCE = 3;

vec3 blend_difference(vec3 base, vec3 blend){
	return abs(base - blend);
}