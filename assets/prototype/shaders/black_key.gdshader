shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.025;
uniform float feather : hint_range(0.001, 0.25) = 0.11;
uniform float exposure : hint_range(0.5, 2.0) = 1.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float brightness = max(source.r, max(source.g, source.b));
	float keep = smoothstep(threshold, threshold + feather, brightness);
	COLOR = vec4(source.rgb * exposure, source.a * keep);
}
