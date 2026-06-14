shader_type canvas_item;
uniform float progress = 0.0;

void fragment() {
	float t = clamp(progress, 0.0, 1.0);
	float d = distance(UV, vec2(0.5));
	float r = t * 0.85;
	COLOR = d < r ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(0.0);
}
