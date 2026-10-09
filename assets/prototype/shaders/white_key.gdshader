shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.82;
uniform float feather : hint_range(0.001, 0.25) = 0.12;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float high = max(source.r, max(source.g, source.b));
	float low = min(source.r, min(source.g, source.b));
	float neutral = 1.0 - clamp((high - low) * 4.0, 0.0, 1.0);
	float key = min(low, high) * neutral;
	float keep = 1.0 - smoothstep(threshold, threshold + feather, key);
	COLOR = vec4(source.rgb, source.a * keep);
}

