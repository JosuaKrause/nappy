class_name GroundFloorChecks
extends RefCounted
## What the ground-floor suites share: where a column's cell is, and what a front's fire escape must
## look like. A helper, not a suite: the runner loads only `test_*.gd`.

## What a building's front shows, read off the pictures it was drawn with (`tests/front_reads.gd`).
const FrontReads := preload("res://tests/front_reads.gd")

## The ground floor's cell of column `col`, in local space: one tile, in the same top-left convention
## every picture's corner is put in (a cell's corner is `(-columns * TILE / 2 + col * TILE, -TILE)`).
static func ground_cell(building: Building, col: int) -> Rect2:
	return Rect2(Vector2(-building.columns() * Building.TILE * 0.5 + col * Building.TILE, -Building.TILE),
			Vector2(Building.TILE, Building.TILE))

static func col_of(building: Building, cell: Rect2) -> int:
	return roundi((cell.position.x + building.columns() * Building.TILE * 0.5) / Building.TILE)

## What `_draw_fire_escape()` puts on a front, asked of one: a balcony on every floor line from
## the first floor's up to the top floor's — none on the ground floor's own, so nothing stands on
## the sidewalk — the lowest the platform alone and every other the balcony with its flight, the
## potted-plant picture or the plain one per that balcony's own roll; and nothing on a front with
## no escape. A wide front's second escape (if any) keeps the minimum gap from the first. Answers
## whether the front had at least one escape, so a sweep can say it was not vacuous.
static func check_fire_escape(t: TestRunner, front: FrontReads, label: String) -> bool:
	var building: Building = front.building
	var escapes: Array[int] = front.escape_cols()
	if escapes.is_empty():
		t.check(front.balcony_count() == 0, "%s: a front with no fire escape draws no piece of one" % label)
		return false
	var balconies: Dictionary = front.balconies()
	var landings: Array[int] = []
	for row: int in balconies[escapes[0]]:
		landings.append(row)
	landings.sort()
	for col in escapes:
		var rows: Array[int] = []
		for row: int in balconies[col]:
			rows.append(row)
		rows.sort()
		t.check(rows == landings, "%s: every escape on a front climbs the same floors (%s, %s)" % [label, rows, landings])
	t.check(building.district == GameEnums.BlockPurpose.RESIDENTIAL,
			"%s: only a residential front carries a fire escape" % label)
	t.check(building.wall_tiles() >= Building.FIRE_ESCAPE_MIN_WALL_ROWS,
			"%s: a front with a fire escape has three floors at least (%d)" % [label, building.wall_tiles()])
	t.check(landings[0] == 1,
			"%s: the lowest balcony is the first floor's, on the ground floor's top edge (row %d)"
			% [label, landings[0]])
	t.check(landings[-1] == building.wall_tiles() - 1,
			"%s: the highest balcony is on the top floor's floor line, so the stack starts at the bottom of the top floor (row %d of %d)"
			% [label, landings[-1], building.wall_tiles()])
	for i in range(1, landings.size()):
		t.check(landings[i] == landings[i - 1] + 1,
				"%s: a balcony on every floor between, so each flight lands on the next (%s)" % [label, landings])
	t.check(escapes.size() <= 2, "%s: a front never carries more than two fire escapes (%d)" % [label, escapes.size()])
	if escapes.size() == 2:
		t.check(absi(escapes[0] - escapes[1]) >= Building.FIRE_ESCAPE_GAP_COLUMNS,
				"%s: two escapes on one front keep the minimum gap (%s, need %d)"
				% [label, escapes, Building.FIRE_ESCAPE_GAP_COLUMNS])
		t.check(building.columns() >= Building.SECOND_FIRE_ESCAPE_MIN_COLUMNS,
				"%s: a second escape only appears on a front wide enough for one (%d columns)"
				% [label, building.columns()])
	for col in escapes:
		t.check(building.columns() < 3 or (col > 0 and col < building.columns() - 1),
				"%s: escape at column %d keeps off the corner columns (%d columns)"
				% [label, col, building.columns()])
		for row in landings:
			var drawn: StringName = balconies[col][row]
			var pot := drawn == Building.FIRE_ESCAPE_A or drawn == Building.FIRE_ESCAPE_PLATFORM_A
			var expected: StringName
			if row == landings[0]:
				expected = Building.FIRE_ESCAPE_PLATFORM_A if pot else Building.FIRE_ESCAPE_PLATFORM_B
			else:
				expected = Building.FIRE_ESCAPE_A if pot else Building.FIRE_ESCAPE_B
			t.check(drawn == expected,
					"%s: column %d row %d draws %s — the platform alone at the bottom, the balcony and its flight above, the pot per its own roll"
					% [label, col, row, expected])
	return true
