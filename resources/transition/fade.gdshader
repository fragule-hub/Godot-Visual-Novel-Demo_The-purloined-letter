shader_type canvas_item;
uniform float progress = 0.0;

void fragment() {
	COLOR = vec4(0.0, 0.0, 0.0, clamp(progress, 0.0, 1.0));
}
