shader_type canvas_item;

uniform vec4 region_uv;
uniform vec2 page_pixel;
uniform float elapsed = 0.0;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 local = (UV - region_uv.xy) / region_uv.zw;
	vec2 drift = vec2(
		sin(elapsed * 0.7) * sin(local.y * 6.283185) * 0.65,
		sin(elapsed * 0.5) * sin(local.x * 6.283185) * 0.35
	);
	vec2 sample_uv = region_uv.xy + fract(local + drift / 32.0) * region_uv.zw;
	sample_uv = clamp(
		sample_uv,
		region_uv.xy + page_pixel * 0.5,
		region_uv.xy + region_uv.zw - page_pixel * 0.5
	);
	COLOR = texture(TEXTURE, sample_uv) * tint;
}
