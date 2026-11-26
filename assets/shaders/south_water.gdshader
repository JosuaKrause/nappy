shader_type canvas_item;
// The south water (amber-puffin): a blue base crossed by the white outlines of the Voronoi
// regions of randomly placed centroids, each centroid's intensity oscillating so the outlines
// drift "in a way water looks" (mossy-ferret #708). `SouthWaterTile` draws it into one square
// tile, which every south-water surface repeats; no other water draws it.
//
// One centroid sits in each square cell of `cell_size` pixels, jittered inside it, so a pixel
// only weighs the nine cells around its own and its cost does not grow with the area drawn. A
// jitter of at most 0.8 of a cell and an intensity of at most 0.3 of one keep the true nearest
// and second-nearest centroids inside those nine.

// The water's blue, #215979, under the outlines.
uniform vec4 base_color : source_color = vec4(0.129, 0.349, 0.475, 1.0);
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.85);
// Pixels between neighbouring centroids, on average. The tile is drawn a texel a world pixel.
uniform float cell_size = 48.0;
// How far a centroid may sit from its cell's centre, as a share of the cell.
uniform float jitter = 0.8;
// The largest intensity a centroid swings to either side, in cells: the outline between two
// centroids moves by about half the difference of their intensities.
uniform float amplitude = 0.25;
// The width of an outline, in pixels.
uniform float line_width = 1.25;
// Each centroid oscillates with its own period, drawn between these two, in seconds.
uniform float min_period = 3.0;
uniform float max_period = 7.0;
// 0: the intensity is subtracted from the distance, and the outlines are curves. 1: from the
// squared distance (a power diagram), and the outlines stay straight.
uniform int metric = 0;
// Above 0, the centroids repeat every this many cells in both directions, so a square of that
// many cells is a seamless tile.
uniform int wrap_cells = 0;
// The water's clock, in seconds; the caller advances it, and holds it still to pause.
uniform float elapsed = 0.0;

varying vec2 world;
// The draw's own colour, which the drawing is multiplied by: white for the tile, transparent for
// the boot's warmup draw, which compiles the shader without showing anything.
varying vec4 tint;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	tint = COLOR;
}

// Four uniform values in [0, 1) from a cell's coordinates, without sin(), whose precision on a
// phone's GPU is too low for a hash (Dave Hoskins, "Hash without Sine").
vec4 hash42(vec2 p) {
	vec4 p4 = fract(p.xyxy * vec4(0.1031, 0.1030, 0.0973, 0.1099));
	p4 += dot(p4, p4.wzxy + 33.33);
	return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

void fragment() {
	vec2 at = world / cell_size;
	vec2 cell = floor(at);
	float nearest = 1e9;
	float second = 1e9;
	vec2 nearest_slope = vec2(0.0);
	vec2 second_slope = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 here = cell + vec2(float(x), float(y));
			vec2 key = here;
			if (wrap_cells > 0) {
				key = mod(here, float(wrap_cells));
			}
			vec4 roll = hash42(key + 0.5);
			vec2 centroid = here + 0.5 + (roll.xy - 0.5) * jitter;
			float rate = TAU / mix(min_period, max_period, roll.z);
			float intensity = amplitude * sin(rate * elapsed + TAU * roll.w);
			vec2 away = at - centroid;
			float reach;
			vec2 slope;
			if (metric == 0) {
				float span = length(away);
				reach = span - intensity;
				slope = away / max(span, 1e-4);
			} else {
				reach = dot(away, away) - intensity;
				slope = 2.0 * away;
			}
			if (reach < nearest) {
				second = nearest;
				second_slope = nearest_slope;
				nearest = reach;
				nearest_slope = slope;
			} else if (reach < second) {
				second = reach;
				second_slope = slope;
			}
		}
	}
	// The outline is where the two smallest reaches are equal; their difference over the length
	// of its gradient is the distance to it, to first order, in cells.
	float gap = (second - nearest) / max(length(second_slope - nearest_slope), 1e-4) * cell_size;
	// One drawn pixel, in the drawing's own pixels, for an edge that is smooth at any scale.
	float pixel = max(length(fwidth(world)) * 0.7071, 1e-4);
	float half_width = line_width * 0.5;
	float coverage = 1.0 - smoothstep(half_width - pixel * 0.5, half_width + pixel * 0.5, gap);
	COLOR = vec4(mix(base_color.rgb, line_color.rgb, coverage * line_color.a), 1.0) * tint;
}
