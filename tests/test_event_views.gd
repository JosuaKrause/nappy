extends RefCounted
## M108, eight-direction entity graphics: binding live event people, animals and riders to
## `EightDirection`. `tests/test_walker_views.gd` already pins the selector itself and the crowd
## walker's own wiring; this suite pins the event side of the same convention —
## `EventInstance.EIGHT_VIEW_BY_SECTOR`, `_select_view()`, and each family's own `_BY_VIEW` table
## and heading source.
##
## Consistent with every other suite in this file, nothing here calls a `_draw_*` function
## directly — `Sprites.draw_standing()` and the raw `canvas.draw_*` calls inside them are only
## valid from an actual draw pass, which is why `_protester_texture()` and `_cap_offset()` are the
## existing model: a `_draw_*` function reads a small, directly testable query, and this suite pins
## the query rather than the drawing. The rendered evidence sheet under
## `docs/evidence/m108-event-people-2026-09-11/` is what a screenshot answers that a test cannot —
## see the **verify** skill, "test what a screenshot cannot see, screenshot what a test cannot
## judge."

const STEP := 1.0 / 60.0

## `EightDirection`'s own sector order (0 E .. 7 NE), and the view/mirror `docs/GRAPHICS.md`'s
## mirror convention says each one draws — identical to `CrowdAgent.WALKER_VIEW_BY_SECTOR` and
## `tests/test_walker_views.gd`'s own `EXPECTED_VIEW`/`EXPECTED_MIRRORED`, since every family below
## shares the one table.
const EXPECTED_VIEW: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]
const EXPECTED_MIRRORED: Array[bool] = [false, false, false, true, true, true, false, false]

## Every family's own five-view table, name to dictionary, so the completeness and distinctness
## checks below run once over the whole set rather than once per family by hand.
const FAMILY_DICTS := {
	"person": EventInstance.PERSON_BY_VIEW,
	"yeller": EventInstance.YELLER_BY_VIEW,
	"busker": EventInstance.BUSKER_BY_VIEW,
	"poster_crew": EventInstance.POSTER_CREW_BY_VIEW,
	"cafe_sitter": EventInstance.CAFE_SITTER_BY_VIEW,
	"van_victim": EventInstance.VAN_VICTIM_BY_VIEW,
	"protester": EventInstance.PROTESTER_BY_VIEW,
	"leaf_blower": EventInstance.LEAF_BLOWER_BY_VIEW,
	"robber_waiting": EventInstance.ROBBER_WAITING_BY_VIEW,
	"robber_lunging": EventInstance.ROBBER_LUNGING_BY_VIEW,
	"chatting_mother_walking": EventInstance.CHATTING_MOTHER_WALKING_BY_VIEW,
	"chatting_mother_talking": EventInstance.CHATTING_MOTHER_TALKING_BY_VIEW,
	"cat_crouched": EventInstance.CAT_CROUCHED_BY_VIEW,
	"cat_running": EventInstance.CAT_RUNNING_BY_VIEW,
	"dog": EventInstance.DOG_BY_VIEW,
	"charging_dog": EventInstance.CHARGING_DOG_BY_VIEW,
	"cyclist": EventInstance.CYCLIST_BY_VIEW,
	"pigeon": EventInstance.PIGEON_BY_VIEW,
	"pigeon_down": EventInstance.PIGEON_DOWN_BY_VIEW,
}

## The animal/rider families whose `"side"` entry is required to be the exact pre-existing
## canonical constant rather than a second preload of the same picture — see
## `docs/GRAPHICS.md`'s instruction to replace a preload "only where the suffixed side ... is the
## same picture," and `docs/evidence/svg-vehicles-2026-09-10/facings.csv`, which marks every one of
## these "existing canonical source."
const ANIMAL_SIDE_REUSE := {
	"cat_crouched": EventInstance.CAT_CROUCHED,
	"cat_running": EventInstance.CAT_RUNNING,
	"dog": EventInstance.DOG,
	"charging_dog": EventInstance.CHARGING_DOG,
	"cyclist": EventInstance.CYCLIST,
	"pigeon": EventInstance.PIGEON,
	"pigeon_down": EventInstance.PIGEON_DOWN,
}

func run(t) -> void:
	_test_eight_view_by_sector_matches_convention(t)
	_test_select_view_holds_and_mirrors(t)
	_test_select_view_zero_heading_holds(t)
	_test_family_dictionaries_are_complete(t)
	_test_animal_side_view_reuses_the_canonical_source(t)
	_test_people_views_are_five_distinct_pictures(t)
	_test_state_pairs_stay_visually_distinct(t)
	_test_setup_resets_the_view_to_the_exact_siting(t)
	_test_robber_waiting_faces_her(t)
	_test_robber_waiting_falls_back_to_its_siting_with_no_player(t)
	_test_robber_lunging_faces_her_through_the_chase(t)
	_test_cat_state_predicate_selects_the_telegraph_posture(t)
	_test_chatting_mother_state_predicate_selects_the_conversation_posture(t)
	_test_unpaired_event_views_still_fall_back_to_svg(t)

func _heading_for_sector(sector: int) -> Vector2:
	return Vector2.from_angle(deg_to_rad(sector * 45.0))

# ------------------------------------------------------------------- the selector wiring ---

func _test_eight_view_by_sector_matches_convention(t) -> void:
	for sector in range(8):
		t.check(EventInstance.EIGHT_VIEW_BY_SECTOR[sector] == EXPECTED_VIEW[sector],
				"sector %d names the %s view" % [sector, EXPECTED_VIEW[sector]])
		t.check(EightDirection.is_mirrored(sector) == EXPECTED_MIRRORED[sector],
				"sector %d mirrors according to the west convention" % sector)

## `_select_view()` is what every `_draw_*` below reads instead of repeating
## `EightDirection.update()` and the table lookup itself — this pins that wiring once, over all
## eight headings, rather than once per family that calls it.
func _test_select_view_holds_and_mirrors(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("busker"), Vector2.ZERO)
	for sector in range(8):
		# Started from the opposite sector every time, so a pass here is never an accident of the
		# previous iteration's hold agreeing with this one.
		instance._view_sector = (sector + 4) % 8
		var view := instance._select_view(_heading_for_sector(sector))
		t.check(view == EXPECTED_VIEW[sector],
				"heading %d degrees selects the %s view (got %s)"
				% [sector * 45, EXPECTED_VIEW[sector], view])
		t.check(EightDirection.is_mirrored(instance._view_sector) == EXPECTED_MIRRORED[sector],
				"sector %d mirror flag matches the west convention" % sector)
	instance.free()

## The one behaviour worth pinning at the wiring level rather than trusting `EightDirection`'s own
## suite to cover by proxy: `_select_view()` passes no idle floor of its own (every heading fed to
## it below is already a unit vector that is never actually zero), so an exactly-zero heading still
## holds through `EightDirection.update()`'s own default threshold — the same "stopped actor keeps
## its last facing" contract the walkers get, reached the same way `Stroller` reaches it.
func _test_select_view_zero_heading_holds(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("busker"), Vector2.ZERO)
	instance._view_sector = 0
	var view := instance._select_view(Vector2.ZERO)
	t.check(view == "side" and instance._view_sector == 0,
			"an exactly zero heading holds whatever sector was last drawn")
	instance.free()

# ------------------------------------------------------------------- the tables ---

func _test_family_dictionaries_are_complete(t) -> void:
	for name in FAMILY_DICTS:
		var by_view: Dictionary = FAMILY_DICTS[name]
		t.check(by_view.size() == 5, "%s carries exactly five authored views" % name)
		for view in EXPECTED_VIEW:
			t.check(by_view.has(view) and by_view[view] != null,
					"%s has a resolving %s view" % [name, view])

func _test_animal_side_view_reuses_the_canonical_source(t) -> void:
	for name in ANIMAL_SIDE_REUSE:
		var by_view: Dictionary = FAMILY_DICTS[name]
		t.check(by_view["side"] == ANIMAL_SIDE_REUSE[name],
				"%s's side view is the same picture as its existing canonical source" % name)

## The people families' five views are freshly authored rather than reusing an old flat picture —
## `busker.svg` and `busker_side.svg` differ on disk, unlike the animal families above — so a
## copy-paste that preloaded one file under two keys would otherwise pass unnoticed.
func _test_people_views_are_five_distinct_pictures(t) -> void:
	var people := FAMILY_DICTS.keys().filter(func(name: String) -> bool:
		return not ANIMAL_SIDE_REUSE.has(name))
	for name in people:
		var by_view: Dictionary = FAMILY_DICTS[name]
		var textures := by_view.values()
		for i in textures.size():
			for j in range(i + 1, textures.size()):
				t.check(textures[i] != textures[j],
						"%s's own five views are five different pictures" % name)

## Two states sharing a view name must never be the same asset, or the state a player is meant to
## read at a glance — crouched against running, waiting against lunging, strolling against talking,
## wings up against wings down — is invisible.
func _test_state_pairs_stay_visually_distinct(t) -> void:
	var pairs := [
		["cat_crouched", "cat_running"], ["robber_waiting", "robber_lunging"],
		["chatting_mother_walking", "chatting_mother_talking"], ["pigeon", "pigeon_down"],
	]
	for pair in pairs:
		var a: Dictionary = FAMILY_DICTS[pair[0]]
		var b: Dictionary = FAMILY_DICTS[pair[1]]
		for view in EXPECTED_VIEW:
			t.check(a[view] != b[view],
					"%s and %s draw different pictures for the %s view" % [pair[0], pair[1], view])

# ------------------------------------------------------------------- fresh placement ---

## `setup()` resets `_view_sector` to the exact nearest sector for the instance's own siting —
## `EightDirection.nearest()`'s own "no prior-view hold on a fresh placement" rule — rather than
## leaving a stale hold from whatever the field's zero-value default happens to be.
func _test_setup_resets_the_view_to_the_exact_siting(t) -> void:
	var instance := EventInstance.new()
	for sector in range(8):
		instance.setup(EventCatalogue.by_id("busker"), Vector2.ZERO, PackedVector2Array(),
				_heading_for_sector(sector))
		t.check(instance._view_sector == sector,
				"a fresh siting at %d degrees starts on sector %d directly (got %d)"
				% [sector * 45, sector, instance._view_sector])
	instance.free()

# ------------------------------------------------------------------- targeted facing ---

## "A stationary actor whose action has a target faces that target": the waiting robber has not
## noticed her yet (`is_waiting()` stays true — `_chase()` only turns `_heading` toward her once
## she is inside `pursues_within`), but a man only watching the street is worth nothing next to a
## man watching *her*, so `_robber_waiting_heading()` reads `player_at` directly.
func _test_robber_waiting_faces_her(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.is_waiting(), "nobody has come near him yet")
	for sector in range(8):
		# Well outside `pursues_within` (140px), so he never actually notices her — this is the
		# waiting posture's own facing, not the notice turning `_heading` for it.
		instance.player_at = _heading_for_sector(sector) * (def.pursues_within + 40.0)
		var heading := instance._robber_waiting_heading()
		t.check(instance.is_waiting(), "still only waiting at sector %d" % sector)
		var view := instance._select_view(heading)
		t.check(view == EXPECTED_VIEW[sector],
				"waiting toward sector %d faces the %s view (got %s)"
				% [sector, EXPECTED_VIEW[sector], view])
	instance.free()

func _test_robber_waiting_falls_back_to_its_siting_with_no_player(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), _heading_for_sector(6))
	t.check(instance.player_at == Vector2.INF, "a data-level rig has no player position at all")
	t.check(instance._robber_waiting_heading() == instance._heading,
			"with nothing to face, the waiting posture keeps the site's own authored facing")
	instance.free()

## Once he has noticed her, `_chase()` keeps `_heading` pointed at her for the whole of the
## telegraph and the chase — "a lunging robber faces its lunge" is this, already true through the
## existing pursuit code, and this test is what proves the drawing actually reads it.
func _test_robber_lunging_faces_her_through_the_chase(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	# Southeast of him and inside `pursues_within`, so one `_chase()` step notices her and turns to
	# face her.
	var her := _heading_for_sector(1) * (def.pursues_within - 10.0)
	instance.player_at = her
	instance._process(STEP)
	t.check(not instance.is_waiting(), "he has noticed her")
	var expected := (her - instance.global_position).normalized()
	t.check(instance._heading.is_equal_approx(expected), "he turned to face her exactly")
	var view := instance._select_view(instance._heading)
	t.check(view == "front_diagonal", "facing southeast draws the front_diagonal view (got %s)"
			% view)
	instance.free()

# ------------------------------------------------------------------- state predicates ---

func _test_cat_state_predicate_selects_the_telegraph_posture(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.is_telegraphing(), "a cat starts in its crouch")
	for i in int(round((def.telegraph_time + 0.05) / STEP)):
		instance._process(STEP)
	t.check(not instance.is_telegraphing(), "and is running once the telegraph ends")
	instance.free()

func _test_chatting_mother_state_predicate_selects_the_conversation_posture(t) -> void:
	var def := EventCatalogue.by_id("chatting_mother")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(not instance.is_chatting(), "she is only strolling until spoken to")
	instance.start_chat()
	t.check(instance.is_chatting(), "and talking for the length of the conversation")
	instance.free()

# ------------------------------------------------------------------- texture fallback ---

## `docs/GRAPHICS.md`: PNG generation for these families stays with M109, so every one of them must
## still resolve in both selection modes today — the same fallback `tests/test_walker_views.gd`
## pins for the crowd walker's own diagonal.
func _test_unpaired_event_views_still_fall_back_to_svg(t) -> void:
	var diagonal: Texture2D = EventInstance.PERSON_BY_VIEW["front_diagonal"]
	TextureResolver.reset_for_tests(true)
	t.check(TextureResolver.resolve(diagonal) == diagonal,
			"explicit SVG mode keeps the authored event diagonal SVG")
	TextureResolver.reset_for_tests(false)
	t.check(TextureResolver.resolve(diagonal) == diagonal,
			"no PNG transfer exists yet, so default mode falls back to the same event SVG")
	TextureResolver.reset_for_tests(DevFlags.svg_requested())
