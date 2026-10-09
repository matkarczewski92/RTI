shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.82;
uniform float feather : hint_range(0.001, 0.25) = 0.12;
uniform float saturation : hint_range(0.5, 1.5) = 1.04;

vec3 center_tone(vec3 color) {
	float source_luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float target_luminance = clamp(0.74 * (0.4565 * source_luminance * source_luminance * source_luminance + 0.4559 * source_luminance * source_luminance + 0.1371 * source_luminance + 0.006), 0.0, 1.0);
	vec3 curved = color * (target_luminance / max(source_luminance, 0.0005));
	float luminance = dot(curved, vec3(0.2126, 0.7152, 0.0722));
	return clamp(mix(vec3(luminance), curved, saturation), vec3(0.0), vec3(1.0));
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float high = max(source.r, max(source.g, source.b));
	float low = min(source.r, min(source.g, source.b));
	float neutral = 1.0 - clamp((high - low) * 4.0, 0.0, 1.0);
	float key = min(low, high) * neutral;
	float keep = 1.0 - smoothstep(threshold, threshold + feather, key);
	COLOR = vec4(center_tone(source.rgb), source.a * keep);
}
