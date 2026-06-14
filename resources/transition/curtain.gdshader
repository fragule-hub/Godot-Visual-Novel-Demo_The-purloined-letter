shader_type canvas_item;
uniform float progress = 0.0;

void fragment() {
	float t = clamp(progress, 0.0, 1.0);
	float bar = t * 0.5 + 0.005;
	if (UV.y < bar || UV.y > 1.0 - bar) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
