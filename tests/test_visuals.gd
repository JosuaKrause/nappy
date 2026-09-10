extends RefCounted
## Focused contracts for opt-in SVG style transfer textures.

const MOTHER: Texture2D = preload("res://assets/rig/mother_side_a.svg")
const SHADOW: Texture2D = preload("res://assets/props/shadow.svg")
const SOURCES: Array[Texture2D] = [
	preload("res://assets/rig/mother_front_a.svg"), preload("res://assets/rig/mother_front_b.svg"),
	preload("res://assets/rig/mother_back_a.svg"), preload("res://assets/rig/mother_back_b.svg"),
	preload("res://assets/rig/mother_side_a.svg"), preload("res://assets/rig/mother_side_b.svg"),
	preload("res://assets/rig/pram_front.svg"), preload("res://assets/rig/pram_back.svg"),
	preload("res://assets/rig/pram_side.svg")]

func run(t) -> void:
	TextureResolver.reset_for_tests(false)
	t.check(TextureResolver.resolve(MOTHER) == MOTHER, "legacy mode keeps the authored SVG")
	t.check(TextureResolver.transfer_path_for(MOTHER) ==
		"res://assets/illustrated/svg-transfer/rig/mother_side_a.png",
		"transfers preserve the source path below the assets root")
	TextureResolver.reset_for_tests(true)
	var resolved: Texture2D = TextureResolver.resolve(MOTHER)
	t.check(resolved != MOTHER and resolved.get_size() == MOTHER.get_size(),
		"illustrated mode loads the same-sized PNG transfer")
	for source: Texture2D in SOURCES:
		var transfer: Texture2D = TextureResolver.resolve(source)
		t.check(transfer != source and transfer.get_size() == source.get_size(),
			"each supplied transfer replaces its SVG at native dimensions")
		var source_image := source.get_image()
		var transfer_image := transfer.get_image()
		var alpha_matches := true
		for y in source_image.get_height():
			for x in source_image.get_width():
				if not is_equal_approx(source_image.get_pixel(x, y).a,
						transfer_image.get_pixel(x, y).a):
					alpha_matches = false
		t.check(alpha_matches, "transfer retains the SVG alpha mask")
	t.check(TextureResolver.resolve(SHADOW) == SHADOW,
		"a missing transfer falls back to the authored SVG")
	t.check(TextureResolver.resolve(resolved) == resolved,
		"a resolved PNG is idempotent and does not construct a second transfer path")
	t.check(TextureResolver.resolve(MOTHER) == resolved,
		"resolved textures are cached rather than loaded repeatedly")
	TextureResolver.reset_for_tests(DevFlags.illustrated_requested())
