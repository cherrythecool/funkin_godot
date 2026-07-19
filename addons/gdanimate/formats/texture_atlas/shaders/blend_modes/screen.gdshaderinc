const int BLEND_SCREEN = 12;

vec3 blend_screen(vec3 base, vec3 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}