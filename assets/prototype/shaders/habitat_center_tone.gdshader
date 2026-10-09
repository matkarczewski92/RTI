shader_type canvas_item;

// CENTER cards are much smaller than the habitat modals.  This curve opens
// their painted midtones while retaining a genuinely dark floor, instead of
// flattening the scene with a uniform exposure multiplier.
uniform float saturation : hint_range(0.5, 1.5) = 1.04;

vec3 center_tone(vec3 color) {
	float source_luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float target_luminance = clamp(0.74 * (
		0.4565 * source_luminance * source_luminance * source_luminance
		+ 0.4559 * source_luminance * source_luminance
		+ 0.1371 * source_luminance
		+ 0.006),
		0.0,
		1.0
	);
	vec3 curved = color * (target_luminance / max(source_luminance, 0.0005));
	float luminance = dot(curved, vec3(0.2126, 0.7152, 0.0722));
	return clamp(mix(vec3(luminance), curved, saturation), vec3(0.0), vec3(1.0));
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(center_tone(source.rgb), source.a);
}
