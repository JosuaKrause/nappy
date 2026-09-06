extends RefCounted
## Visual geometry relationships that headless route tests cannot see.

func run(t) -> void:
	for seed in [3199523899, 4242, 7777, 12004, 90210]:
		var map := CityGenerator.generate(seed)
		var frontage := City.home_door_frontage(map)
		var rect: Rect2i = frontage[0]
		var side: int = frontage[1]
		t.check(rect.size != Vector2i.ZERO,
				"seed %d: home door has a real building frontage" % seed)
		var home := map.home_rect
		var touches_side := (side == -1 and rect.end.x == home.position.x) \
				or (side == 1 and rect.position.x == home.end.x)
		var touches_north := side == 0 and rect.end.y == home.position.y
		t.check(touches_side or touches_north,
				"seed %d: door frontage is on the home boundary, not an alley" % seed)
