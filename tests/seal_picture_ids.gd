class_name SealPictureIds
extends RefCounted
## The ids of the seal pictures the seal planner stands, for the suites that hold each picture to its
## shape. A suite asks a picture's table row through `SealPlanner.candidate_named()`; this list is
## what it walks, and `test_seals` holds that every row a day's sited seals stand belongs to one of
## these pictures, so a picture the planner gains and sites is found there.

static func every() -> Array[String]:
	return [
		"barricade_seal",
		"construction_pair",
		"cafe_pair",
		"market_pair",
		"delivery_pair",
		"fallen_tree_seal",
		"car_accident_seal",
		"skip_scaffolding_pair",
		"burst_main_seal",
		"moving_van_pair",
		"burnt_out_car_seal",
		"collapsed_frontage_seal",
	]
