shader_type canvas_item;

uniform float speed = 0.03;
uniform vec3 color_a : source_color = vec3(0.06, 0.14, 0.18);
uniform vec3 color_b : source_color = vec3(0.04, 0.08, 0.22);

void fragment() {
	float t = sin(TIME * speed + UV.y * 4.0 + UV.x * 1.5) * 0.5 + 0.5;
	COLOR.rgb = mix(color_a, color_b, t);
	COLOR.a = 1.0;
}
