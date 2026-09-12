shader_type canvas_item;

uniform float hue = 0.0;
uniform float saturation = 0.0;
uniform float contrast = 0.0;
uniform float brightness = 0.0;

vec3 apply_hue(vec3 color) {
    vec3 k = vec3(0.57735);
    float angle = radians(hue);
    float cos_angle = cos(angle);
    return color * cos_angle + cross(k, color) * sin(angle) + k * dot(k, color) * (1.0 - cos_angle);
}

vec3 apply_hscb(vec3 color) {
    color = clamp(color + ((brightness) / 255.0), 0.0, 1.0);
    color = apply_hue(color);
    color = clamp((color - 0.5) * (1.0 + ((contrast) / 255.0)) + 0.5, 0.0, 1.0);

    vec3 intensity = vec3(dot(color, vec3(0.30980392156, 0.60784313725, 0.08235294117)));
    color = clamp(mix(intensity, color, (1.0 + (saturation / 100.0))), 0.0, 1.0);

    return color;
}

void fragment() {
	COLOR.rgb = apply_hscb(COLOR.rgb);
}
