extends RefCounted
## Every mast is outside the zero-cost line (`EventScheduler._counts_against_the_line`): the six
## fixed ones by their `mast_id`, and the two day 11 adds — queued near the mark and routed onto her
## walk — by being a `loudspeaker` while they are still being sited, before any id is given them.
## The player's answer (inbox #684 in coral-lark, "Exempt like fixed masts"), so that the routed mast has a place
## on her route in every city rather than in about a third of them. `tests/test_resistance_arrow.gd`'s
## day-11 check walks the cities; this is the rule alone. A mast keeps being a plan the other
## rows count nothing for, and an ordinary row with the same field still counts.

func run(t) -> void:
	var mast := EventCatalogue.by_id("loudspeaker")
	var yeller := EventCatalogue.by_id("homeless_yeller")
	var here := Vector2(100, 100)
	var sited := EventScheduler.Planned.new(mast, here)
	t.check(not EventScheduler._counts_against_the_line(sited),
			"a mast being sited, with no id yet, does not count against the line")
	var fixed := EventScheduler.Planned.new(mast, here)
	fixed.mast_id = "site-0"
	t.check(not EventScheduler._counts_against_the_line(fixed),
			"a fixed mast does not count against the line")
	var added := EventScheduler.Planned.new(mast, here)
	added.mast_id = EventScheduler.added_mast_id(here)
	t.check(not EventScheduler._counts_against_the_line(added),
			"a queued or routed mast, named by its foot, does not count against the line")
	var shouting := EventScheduler.Planned.new(yeller, here)
	t.check(EventScheduler._counts_against_the_line(shouting),
			"the man shouting, with the same field, still counts")
