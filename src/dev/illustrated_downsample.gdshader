shader_type canvas_item;
render_mode unshaded, blend_disabled;

// The root viewport's GLES blit selects one source pixel per output pixel. Every high-resolution
// pixel in a 2x2 block therefore carries the same box-filtered colour, so that selection resolves
// the intended average regardless of its phase.
uniform sampler2D scene : hint_screen_texture, filter_nearest;

void fragment() {
	vec2 source_pixel = floor(SCREEN_UV / SCREEN_PIXEL_SIZE);
	vec2 block = floor(source_pixel * 0.5) * 2.0;
	vec2 first = (block + vec2(0.5)) * SCREEN_PIXEL_SIZE;
	vec2 x = vec2(SCREEN_PIXEL_SIZE.x, 0.0);
	vec2 y = vec2(0.0, SCREEN_PIXEL_SIZE.y);
	COLOR = (texture(scene, first) + texture(scene, first + x) +
			texture(scene, first + y) + texture(scene, first + x + y)) * 0.25;
}
