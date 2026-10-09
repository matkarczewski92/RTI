shader_type canvas_item;

uniform float exposure : hint_range(0.5, 2.0) = 1.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(source.rgb * exposure, source.a);
}
