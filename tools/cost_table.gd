extends Node
## Generates and checks `docs/COSTS.md` — the checked-in survey of what every catalogue row
## costs, computed from the same `EventDef`/`EventInstance`/`Tuning` code the game charges with.
## See that file's own header for what each table means; see `tools/cost-table.sh` for the
## entry point anybody should use.
##
##     godot --headless --path . res://tools/cost_table.tscn --            # rewrite the file
##     godot --headless --path . res://tools/cost_table.tscn -- --check    # compare, write nothing
##
## Runs as a scene, not via `--script`: every column reads the `Tuning` autoload and walks a real
## `EventCatalogue`, and `--script` starts no scene tree of the project's own, so no autoload
## exists there — see `tests/run_tests.gd`'s own doc comment for the same reason stated about the
## test suite. `EventDef`, `EventScheduler` and `M174Pass` (`tests/probes/m174_pass.gd`) resolve
## by their global `class_name` the same way from here as from anywhere else in the project —
## `tools/` being excluded from the resource scan (`tools/.gdignore`) keeps this script's own
## class out of that registry, it does not stop this script reading classes registered by others.
##
## PLAYTEST-115: *"the 'survey' should happen automatically every time and should show up in the
## commit diff if it changes"*; *"do computations at fixed distances across all objects ... that
## way we can get the real impact and not the relative impact dependent on the object"*.

const OUTPUT_PATH := "res://docs/COSTS.md"

## `current_intensity()`'s pulse envelope (`0.25 + 0.75·(0.5 − 0.5·cos(phase))`) averages to
## exactly this over one full period, regardless of `pulse_period` — see
## `tests/probes/m174_walk_beside.gd`'s own derivation, reused here rather than re-argued.
const PULSE_MEAN := 0.625

## Fixed distances in px, identical for every row — dense inside the first hundred where the
## inner radii sit, and the last one past the widest `outer_radius` in the catalogue so it reads
## the bare decay for every row. `_assert_distances_clear_every_outer_radius()` checks that
## assumption rather than trusting the comment.
const DISTANCES: Array[float] = [0.0, 25.0, 50.0, 75.0, 100.0, 150.0, 200.0, 300.0, 400.0, 550.0]
const DISTANCE_COLS: Array[String] = ["d0", "d25", "d50", "d75", "d100", "d150", "d200", "d300",
		"d400", "d550"]
const DISTANCE_HEADERS: Array[String] = ["0px", "25px", "50px", "75px", "100px", "150px", "200px",
		"300px", "400px", "550px"]

## The pass offsets are `M174Pass.OFFSETS` itself, read live rather than copied, so the two can
## never silently disagree about which px a column is. `PASS_COLS`/`PASS_HEADERS` still have to
## be declared here in the matching order; `_assert_pass_offsets_match()` checks that pairing
## once at start-up instead of trusting it.
const PASS_COLS: Array[String] = ["p0", "p20", "p40", "p80", "p120"]
const PASS_HEADERS: Array[String] = ["0px", "20px", "40px", "80px", "120px"]

const GEOMETRY_COLS: Array[String] = ["role", "intensity", "core_intensity", "core_radius",
		"inner_radius", "outer_radius", "falloff_power", "pulse_period", "pulse_trough", "speed",
		"walk_through_cost"]
const GEOMETRY_HEADERS: Array[String] = ["role", "intensity", "core_intensity", "core_radius",
		"inner_radius", "outer_radius", "falloff_power", "pulse_period", "pulse_trough", "speed",
		"walk_through_cost"]

const TITLE_GEOMETRY := "Geometry and role"
const TITLE_DISTANCE_AWAKE := "Walking at a fixed distance — awake"
const TITLE_DISTANCE_ASLEEP := "Walking at a fixed distance — asleep"
const TITLE_PASS_AWAKE := "The pass — awake"
const TITLE_PASS_ASLEEP := "The pass — asleep"
const TABLE_TITLES := [TITLE_GEOMETRY, TITLE_DISTANCE_AWAKE, TITLE_DISTANCE_ASLEEP,
		TITLE_PASS_AWAKE, TITLE_PASS_ASLEEP]

const ID_WIDTH := 20

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var check_mode := false
	for arg in args:
		if arg == "--check":
			check_mode = true
		else:
			push_error("tools/cost_table.gd: unknown argument '%s' (want --check or nothing)" % arg)
			get_tree().quit(2)
			return

	var rows := _included_rows()
	if not _assert_distances_clear_every_outer_radius(rows):
		get_tree().quit(1)
		return
	if not _assert_pass_offsets_match():
		get_tree().quit(1)
		return

	var tables := _build_tables(rows)
	var content := _render(tables)

	if check_mode:
		get_tree().quit(_check(tables, content))
	else:
		_write(content)
		get_tree().quit(0)

# ------------------------------------------------------------------ row selection ---

## Every catalogue row except the city-wide ones — `curfew_announce`, `loudspeaker` — which have
## no distance to be measured at (`EventDef.walk_through_cost()` answers zero for them by
## construction; `city_wide` events apply everywhere at once rather than falling away from a
## place). Catalogue order, not sorted: a new row appended to `EventCatalogue._build()` appends
## here too, which is what "fixed row order" means for a table that is meant to diff cleanly when
## one row's numbers move rather than when the whole table gets re-sorted under it.
func _included_rows() -> Array[EventDef]:
	var out: Array[EventDef] = []
	for def in EventCatalogue.all():
		if def.city_wide:
			continue
		out.append(def)
	return out

## Rows whose notice/chase state (`is_waiting()`, `_chase()`) is driven by `EventInstance.
## player_at`, which `M174Pass`'s rig never sets — its own `_pass_net()` walks a fixed straight
## line and never tells the instance where "she" is except through the field it samples. Run
## through the rig anyway, a pursuer would just read as permanently `is_waiting()` (full
## intensity, never chasing) for the whole simulated pass, which is not a pass and would look
## exactly like a measured one. Dashed instead, the way `docs/EVENTS.md`'s own run-through column
## is already empty for every pursuer: "they follow, so there is no crossing to price."
func _pass_excluded(def: EventDef) -> bool:
	return def.pursues or def.pursues_within > 0.0

# ------------------------------------------------------------------------ asserts ---

func _assert_distances_clear_every_outer_radius(rows: Array[EventDef]) -> bool:
	var last: float = DISTANCES[DISTANCES.size() - 1]
	var ok := true
	for def in rows:
		if def.outer_radius >= last:
			push_error(("tools/cost_table.gd: %s has outer_radius %.1fpx, at or past the table's "
					% [def.id, def.outer_radius])
					+ "own last distance %.1fpx — widen DISTANCES so the last column still reads "
					% last + "the bare decay for it")
			ok = false
	return ok

func _assert_pass_offsets_match() -> bool:
	var offsets: Array = M174Pass.OFFSETS
	if offsets.size() != PASS_COLS.size():
		push_error("tools/cost_table.gd: M174Pass.OFFSETS has %d entries, PASS_COLS has %d — "
				% [offsets.size(), PASS_COLS.size()] + "keep them declared in the same order")
		return false
	return true

# --------------------------------------------------------------------- row data ---

func _role_str(def: EventDef) -> String:
	match EventScheduler._role_for(def):
		GameEnums.BlockerRole.WALL:
			return "wall"
		GameEnums.BlockerRole.FRICTION:
			return "friction"
		GameEnums.BlockerRole.SET_PIECE:
			return "set_piece"
		_:
			return "none"

func _geometry_row(def: EventDef) -> Dictionary:
	var row := {}
	row["role"] = _role_str(def)
	row["intensity"] = "%.1f" % def.intensity
	if def.core_intensity > 0.0:
		row["core_intensity"] = "%.1f" % def.core_intensity
		row["core_radius"] = "%.1f" % def.core_radius
	else:
		row["core_intensity"] = "—"
		row["core_radius"] = "—"
	row["inner_radius"] = "%.1f" % def.inner_radius
	row["outer_radius"] = "%.1f" % def.outer_radius
	row["falloff_power"] = "%.1f" % def.falloff_power
	if def.pulse_period > 0.0:
		row["pulse_period"] = "%.1f" % def.pulse_period
		row["pulse_trough"] = "%.1f" % (def.intensity * 0.25)
	else:
		row["pulse_period"] = "—"
		row["pulse_trough"] = "—"
	# A pursuer's relevant speed is how fast it closes once it notices, not its cold `speed`
	# (almost always 0 for one, since most pursuers wait rather than patrol); everything else
	# that moves reads its own `speed`.
	if def.pursues:
		row["speed"] = "%.1f" % def.pursue_speed
	elif def.mobile and def.speed > 0.0:
		row["speed"] = "%.1f" % def.speed
	else:
		row["speed"] = "—"
	row["walk_through_cost"] = "%.1f" % def.walk_through_cost()
	return row

## Net points a second standing at a fixed distance — the field averaged over the pulse, times
## sensitivity, less the walking decay. A pure query on the def's own data: no instance, no
## notice or chase state, so this is safe and meaningful for every included row, pursuers and
## detainers among them, the same way `EventDef.walk_through_cost()` already prices them.
func _distance_row(def: EventDef, sensitivity: float) -> Dictionary:
	var row := {}
	for i in DISTANCES.size():
		var d: float = DISTANCES[i]
		var base := def.emission_at(Vector2(d, 0.0))
		if def.pulse_period > 0.0:
			base *= PULSE_MEAN
		var net := base * sensitivity - Tuning.EXCITEMENT_DECAY_WALKING
		row[DISTANCE_COLS[i]] = "%.1f" % net
	return row

## Net points from one real pass, `M174Pass.pass_net_averaged()` — the same simulation
## `tests/test_events.gd` runs, moving a real instance the way the game moves it and averaging
## over its own pulse phase. Offset 0 is dashed for a row with a solid, still body
## (`obstructs_radius > 0.0`; anything mobile is exempt from that rule and so never sets one):
## her own body cannot occupy the same line as a thing she cannot walk through.
func _pass_row(def: EventDef, sensitivity: float) -> Dictionary:
	var row := {}
	if _pass_excluded(def):
		for key in PASS_COLS:
			row[key] = "—"
		return row
	var offsets: Array = M174Pass.OFFSETS
	for i in offsets.size():
		var offset: float = offsets[i]
		var key: String = PASS_COLS[i]
		if is_zero_approx(offset) and def.obstructs_radius > 0.0:
			row[key] = "—"
			continue
		var net := M174Pass.pass_net_averaged(def, offset, Tuning.EXCITEMENT_DECAY_WALKING, sensitivity)
		row[key] = "%.1f" % net
	return row

# ------------------------------------------------------------------- table model ---
# One `TableModel` per section: a title, the ordered column keys, the display header for each,
# and one `Dictionary` per row keyed by id, in the row order the table renders and diffs in.

class TableModel:
	var title := ""
	var cols: Array[String] = []
	var headers: Array[String] = []
	var order: Array[String] = []
	var rows: Dictionary = {}  # id -> Dictionary(col -> String)

func _build_tables(rows: Array[EventDef]) -> Array[TableModel]:
	var geometry := TableModel.new()
	geometry.title = TITLE_GEOMETRY
	geometry.cols = GEOMETRY_COLS
	geometry.headers = GEOMETRY_HEADERS

	var distance_awake := TableModel.new()
	distance_awake.title = TITLE_DISTANCE_AWAKE
	distance_awake.cols = DISTANCE_COLS
	distance_awake.headers = DISTANCE_HEADERS

	var distance_asleep := TableModel.new()
	distance_asleep.title = TITLE_DISTANCE_ASLEEP
	distance_asleep.cols = DISTANCE_COLS
	distance_asleep.headers = DISTANCE_HEADERS

	var pass_awake := TableModel.new()
	pass_awake.title = TITLE_PASS_AWAKE
	pass_awake.cols = PASS_COLS
	pass_awake.headers = PASS_HEADERS

	var pass_asleep := TableModel.new()
	pass_asleep.title = TITLE_PASS_ASLEEP
	pass_asleep.cols = PASS_COLS
	pass_asleep.headers = PASS_HEADERS

	for def in rows:
		geometry.order.append(def.id)
		geometry.rows[def.id] = _geometry_row(def)
		distance_awake.order.append(def.id)
		distance_awake.rows[def.id] = _distance_row(def, 1.0)
		distance_asleep.order.append(def.id)
		distance_asleep.rows[def.id] = _distance_row(def, Tuning.SLEEPING_SENSITIVITY)
		pass_awake.order.append(def.id)
		pass_awake.rows[def.id] = _pass_row(def, 1.0)
		pass_asleep.order.append(def.id)
		pass_asleep.rows[def.id] = _pass_row(def, Tuning.SLEEPING_SENSITIVITY)

	return [geometry, distance_awake, distance_asleep, pass_awake, pass_asleep]

# ---------------------------------------------------------------------- render ---

func _pad(s: String, width: int) -> String:
	if s.length() >= width:
		return s
	return s + " ".repeat(width - s.length())

func _pad_right_align(s: String, width: int) -> String:
	if s.length() >= width:
		return s
	return " ".repeat(width - s.length()) + s

## Every column's own fixed width — the header name's own length or 9, whichever is larger, fixed
## once per column rather than measured off the data, so a row whose number gets a digit longer
## can never push a neighbour's column out of place.
func _col_width(header: String) -> int:
	return maxi(9, header.length())

func _render_table(t: TableModel) -> String:
	var out := "## %s\n\n" % t.title
	var header_cells := [_pad("id", ID_WIDTH)]
	var sep_cells := ["-".repeat(ID_WIDTH)]
	for i in t.cols.size():
		var w := _col_width(t.headers[i])
		header_cells.append(_pad_right_align(t.headers[i], w))
		sep_cells.append("-".repeat(w))
	out += "| " + " | ".join(header_cells) + " |\n"
	out += "| " + " | ".join(sep_cells) + " |\n"
	for id in t.order:
		var row: Dictionary = t.rows[id]
		var cells := [_pad(id, ID_WIDTH)]
		for i in t.cols.size():
			var w := _col_width(t.headers[i])
			cells.append(_pad_right_align(String(row[t.cols[i]]), w))
		out += "| " + " | ".join(cells) + " |\n"
	return out

func _header_text() -> String:
	var lines := PackedStringArray()
	lines.append("# What an event costs")
	lines.append("")
	lines.append("Computed from the real catalogue (`EventCatalogue.all()`, catalogue order) and " +
			"the real `Tuning` constants below — never a second copy of the falloff or the decay. " +
			"Regenerate with `tools/cost-table.sh`; `tools/cost-table.sh --check` compares this file " +
			"against a fresh run and names every row and column that moved, old → new, without " +
			"writing anything.")
	lines.append("")
	lines.append("Every figure is on quiet sidewalk (ground multiplier 1.0); other grounds are not " +
			"in this version. The constants each figure below was computed under, one line each so " +
			"a change to any of them shows here as this line moving:")
	lines.append("")
	lines.append("- `Tuning.EXCITEMENT_DECAY_WALKING` = %.1f points/s" % Tuning.EXCITEMENT_DECAY_WALKING)
	lines.append("- `Tuning.SLEEPING_SENSITIVITY` = %.2f" % Tuning.SLEEPING_SENSITIVITY)
	lines.append("- `Tuning.WALK_SPEED` = %.1f px/s" % Tuning.WALK_SPEED)
	lines.append("- `Tuning.WALL_WORTH_OF_COST` = %.1f points" % Tuning.WALL_WORTH_OF_COST)
	lines.append("")
	lines.append("**Excluded from every table**: `curfew_announce` and `loudspeaker`, the two " +
			"`city_wide` rows — they apply everywhere at once rather than falling away from a " +
			"place, so there is no distance to put in a column and `walk_through_cost()` answers " +
			"zero for both by construction.")
	lines.append("")
	lines.append("**`" + TITLE_GEOMETRY + "`** is what a row's own data says, unconditionally: " +
			"`role` is `EventScheduler._role_for()` at day 0 (a row's cold shape, before any " +
			"resistance heat); `core_intensity`/`core_radius` are a dash where a row has no core; " +
			"`pulse_trough` is `intensity * 0.25`, the low point of the pulse envelope " +
			"`current_intensity()` uses, and a dash where a row does not pulse; `speed` is a " +
			"pursuer's `pursue_speed` (almost always faster than its own cold `speed`, which is " +
			"usually 0), a mobile row's own `speed`, and a dash for anything that does not move; " +
			"`walk_through_cost()` is the field integrated along a straight line through the " +
			"centre, less the walking decay over the same crossing.")
	lines.append("")
	lines.append("**`" + TITLE_DISTANCE_AWAKE + "`/`" + TITLE_DISTANCE_ASLEEP + "`** are the net " +
			"points a second while she walks and stays a fixed distance from a row's centre: the field " +
			"(`EventDef.emission_at()`, which is what `contribution_at()` charges) averaged over " +
			"the row's own pulse, times the sleeping sensitivity where the baby is asleep, less " +
			"the walking decay. A pure query on the row's own data — no instance, no notice or " +
			"chase state — so every included row gets a real number here, pursuers and the three " +
			"detainers (`chatting_mother`, `checkpoint_hut`, `checkpoint_post`) included, the same " +
			"way `walk_through_cost()` already prices them: a detainer's real cost is " +
			"`Tuning.CHAT_EXCITEMENT` over the hold rather than this field, so its figures here are " +
			"notional, exactly as `docs/EVENTS.md` already says of its own column.")
	lines.append("")
	lines.append("**`" + TITLE_PASS_AWAKE + "`/`" + TITLE_PASS_ASLEEP + "`** are the net points " +
			"from one real pass at `Tuning.WALK_SPEED` — she and the row's own instance going " +
			"different directions, the row moving exactly as the game moves it (pacing, mobile, " +
			"or held still), averaged over 8 samples of its own pulse phase. `M174Pass." +
			"pass_net_averaged()` (`tests/probes/m174_pass.gd`) is the simulation, shared rather " +
			"than duplicated — `tests/test_events.gd`'s own relationship test runs the identical " +
			"code. Dashed for a pursuer (`pursues` or `pursues_within` set: alley_mouse, " +
			"pigeon_flock, charging_dog, alley_robbery, masked_pursuer) — its notice and chase " +
			"state is driven by where the player is, which the rig never tells it, so there is no " +
			"pass to measure, the same reason `docs/EVENTS.md`'s own run-through column is empty " +
			"for a pursuer. The 0px column is dashed for a row with a solid, still body " +
			"(`obstructs_radius > 0.0`) — she cannot walk the same line as a thing she cannot walk " +
			"through.")
	lines.append("")
	lines.append("Deterministic: fixed row order, fixed decimals (one), a fixed 8-sample pulse " +
			"average, no clock and no seed anywhere in the arithmetic — two runs on the same tree " +
			"write the same bytes.")
	lines.append("")
	return "\n".join(lines)

func _render(tables: Array[TableModel]) -> String:
	var out := _header_text()
	for i in tables.size():
		out += _render_table(tables[i])
		if i < tables.size() - 1:
			out += "\n"
	return out

func _write(content: String) -> void:
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("tools/cost_table.gd: could not write %s (%s)"
				% [OUTPUT_PATH, FileAccess.get_open_error()])
		return
	file.store_string(content)
	file.close()
	print("wrote %s" % OUTPUT_PATH)

# ----------------------------------------------------------------------- check ---

## Parses a rendered table back into `id -> Dictionary(col -> String)`, trusting the same column
## order `_build_tables()` used to write it — this file only ever reads its own format, generated
## by the same code that is about to compare against it, so there is nothing here to be lenient
## about. Returns `{}` and reports a problem through `problems` if the title's section is missing
## or a row's cell count does not match, rather than misreading columns into each other.
func _parse_table(text: String, t: TableModel, problems: Array[String]) -> Dictionary:
	var heading := "## %s" % t.title
	var start := text.find(heading)
	if start < 0:
		problems.append("docs/COSTS.md is missing the '%s' section entirely" % t.title)
		return {}
	var section_start := text.find("\n", start) + 1
	var next_heading := text.find("\n## ", section_start)
	var section := text.substr(section_start) if next_heading < 0 \
			else text.substr(section_start, next_heading - section_start)
	var parsed := {}
	var seen_header := false
	var seen_sep := false
	for line in section.split("\n"):
		if not line.begins_with("|"):
			continue
		if not seen_header:
			seen_header = true
			continue
		if not seen_sep:
			seen_sep = true
			continue
		var cells := line.split("|")
		# A well-formed `| a | b | c |` splits into an empty leading piece, the cells, and an
		# empty trailing piece.
		if cells.size() < 2:
			continue
		cells.remove_at(0)
		cells.remove_at(cells.size() - 1)
		if cells.size() != t.cols.size() + 1:
			problems.append("'%s': a row in docs/COSTS.md has %d cells, wanted %d — regenerate it"
					% [t.title, cells.size(), t.cols.size() + 1])
			continue
		var id := cells[0].strip_edges()
		var row := {}
		for i in t.cols.size():
			row[t.cols[i]] = cells[i + 1].strip_edges()
		parsed[id] = row
	return parsed

## Compares the freshly built `tables` against what is on disk at `OUTPUT_PATH`, cell by cell, and
## prints every row and column that moved, old → new. Returns the exit code: 0 identical,
## 1 different (or the checked-in file cannot be read or parsed at all).
func _check(tables: Array[TableModel], fresh_content: String) -> int:
	if not FileAccess.file_exists(OUTPUT_PATH):
		print("FAIL: %s does not exist — run tools/cost-table.sh once to create it" % OUTPUT_PATH)
		return 1
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.READ)
	var old_content := file.get_as_text()
	file.close()

	if old_content == fresh_content:
		print("docs/COSTS.md is up to date")
		return 0

	var problems: Array[String] = []
	var moved: Array[String] = []
	for t in tables:
		var old_rows := _parse_table(old_content, t, problems)
		if old_rows.is_empty() and not problems.is_empty():
			continue
		var old_ids: Array = old_rows.keys()
		var new_ids: Array = t.order
		for id in new_ids:
			if id not in old_rows:
				moved.append("'%s': new row '%s'" % [t.title, id])
				continue
			var old_row: Dictionary = old_rows[id]
			var new_row: Dictionary = t.rows[id]
			for i in t.cols.size():
				var col: String = t.cols[i]
				var old_value: String = String(old_row.get(col, "?"))
				var new_value: String = String(new_row[col])
				if old_value != new_value:
					moved.append("'%s': %s · %s: %s → %s"
							% [t.title, id, t.headers[i], old_value, new_value])
		for id in old_ids:
			if id not in t.rows:
				moved.append("'%s': row '%s' is gone" % [t.title, id])

	print("FAIL: docs/COSTS.md is stale. tools/cost-table.sh to regenerate it.")
	for problem in problems:
		print("  %s" % problem)
	for line in moved:
		print("  %s" % line)
	if problems.is_empty() and moved.is_empty():
		# The bytes differ (whitespace, header prose) but no cell parsed as different — still a
		# real diff, just not one this parser can attribute to a row/column. Said plainly rather
		# than reported as "0 checks, 0 failures" while still exiting non-zero.
		print("  (the checked-in file differs outside the data rows this parser reads — the " +
				"header prose or a constant line likely moved; regenerate and read the file diff)")
	return 1
