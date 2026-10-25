extends RefCounted
## `Texts` (`src/ui/texts.gd`) is the one place the game's on-screen words live, and this is what
## keeps them there: a quoted sentence anywhere else under `src/` fails the suite unless it is in
## the allow-list below, which names every developer readout, log line and error message that is
## not a text a player reads.
##
## **What counts as a sentence** is a quoted string with two words in it, a letter-run of two or
## more followed by a space and another word or a `%` (so `"Day %d of %d"`, `"press a button"`
## and `"The end."` are sentences, `"res://x"`, `"ui/pause"`, `"%d"` and `"A"` are not).
## Comments are not code, and neither is the argument of a log or error call (`print`,
## `push_warning`, `push_error`, `printerr`, `assert`, `Telemetry.note`, a run trace's `note`), which
## may run over several lines; both are skipped before a string is judged.
##
## A text added to a screen's own script therefore fails here, with the file, the line and the
## text: it belongs in `Texts`, and the caller reads `Texts.<NAME>`. A developer readout is
## the one other home, and goes into `_ALLOWED_FILES` (a whole file or folder, with the reason) or
## `_ALLOWED_LITERALS` (one string in one file, with the reason).

## A whole file or folder of developer-facing strings, by path prefix. Nobody plays these: they are
## the dev overlay's own tooling, the run log, validation errors a generator reports about a map
## it rejected, and the debug HUD's reasons. An entry that no longer shields a sentence fails, so
## the list shrinks when a file stops needing it.
const _ALLOWED_FILES := {
	"res://src/dev/": "developer tooling: rigs, recipes, previews and the dev flags' own messages",
	"res://src/telemetry/": "the run log's own lines",
	"res://src/autoload/telemetry.gd": "the run log's own lines",
	"res://src/autoload/game_save.gd": "the save's own log and error lines",
	"res://src/autoload/game_state.gd": "log notes about nerves and resistance work",
	"res://src/autoload/visit_counter.gd": "the page-count script's own source",
	"res://src/city/building.gd": "map validation errors and recipe checks, reported to a developer",
	"res://src/city/city_generator.gd": "map validation errors and recipe checks, reported to a developer",
	"res://src/city/recipe_city_builder.gd": "map validation errors and recipe checks, reported to a developer",
	"res://src/city/recipe_city_context.gd": "map validation errors and recipe checks, reported to a developer",
	"res://src/routes/road_closure.gd": "the closure kinds' log names",
	"res://src/crowd/crowd_agent.gd": "placement checks reported to a developer",
	"res://src/crowd/crowd.gd": "placement checks reported to a developer",
	"res://src/visuals/atlas_library.gd": "atlas and ground-layer errors reported to a developer",
	"res://src/visuals/ground_layers.gd": "atlas and ground-layer errors reported to a developer",
	"res://src/events/event_scheduler.gd": "placement reasons written to the run log",
	"res://src/events/event_manager.gd": "log notes about placement",
	"res://src/events/checkpoint_controller.gd": "log notes about the doors' crossings",
	"res://src/resistance/resistance_director.gd": "the director's own log lines and setup errors",
	"res://src/player/baby.gd": "the debug HUD's reason a baby is not settling",
}

## One string in one file: a developer readout in a file whose other strings are held to the rule.
const _ALLOWED_LITERALS := {
	"res://src/finale/finale_planner.gd": {
		"%s via %d calm, %d cells%s": "the planner's summary line, written to the run log",
		"%d open streets, %d placements": "the planner's summary line, written to the run log",
	},
	"res://src/run_config.gd": {
		"RunConfig is resolved once at boot and never changes; a write was refused":
				"the warning for a write to a resolved configuration, read by a developer",
	},
	"res://src/main.gd": {
		"build %s": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"seed  %d   day %d%s": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"skip  %s": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"phase %s  %.0fs left": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"tile  %d, %d  (%s)": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"calm  %s    alley  %s": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"speed       %6.1f": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"run excess  %6.2f": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"events      %6d live of %d": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"ahead owed  %6d": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"crowd       %6d": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"nearest     %s": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"incoming    %6.2f /s": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"decay       %6.2f /s": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"net         %6.2f /s": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"arrows/WASD walk": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"shift       run": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"esc         pause  (r restart, q quit)": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"tile  %d, %d  (building)": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"events      %6d live": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"%s %s age=%.1f/%.1f %.0fpx i=%.1f": "the dev overlay's readout (debug builds and `?debug=1` only)",
		"no baby yet": "the run log's capture context",
		"exc %d, sleep %d": "the run log's capture context",
	},
	"res://src/ui/hud.gd": {
		"asleep - go home": "the debug HUD's state line",
		"crying - day lost": "the debug HUD's state line",
		"   (not settling: %s)": "the debug HUD's state line",
		"resistance %s": "the debug HUD's progress line",
		"day %d / %d      act %d      nerves %s": "the debug HUD's header",
	},
}

## Words a quoted string may carry that are not a sentence, kept out of the rule by name.
const _NOT_A_SENTENCE := [
	"res://", "user://", "uid://",
]

func run(t) -> void:
	_test_a_sentence_is_found_and_a_name_is_not(t)
	_test_a_comment_and_a_log_call_are_not_judged(t)
	_test_a_log_call_over_several_lines_is_skipped_to_its_end(t)
	_test_a_log_call_hides_only_its_own_arguments(t)
	_test_the_allow_list_names_only_paths_that_exist(t)
	_test_no_sentence_is_quoted_outside_the_catalogue(t)
	_test_the_catalogue_holds_what_the_screens_say(t)

## Every quoted sentence in `source`, as `[line, text]` pairs. Comments are skipped, and so are the
## arguments of a log or error call (from its opening paren to the one that closes it, over as
## many lines as that takes) -- and only those: a string before the call on the same line, or after
## its closing paren, is judged like any other.
static func sentences_in(source: String) -> Array:
	var found := []
	var log_depth := 0
	var number := 0
	for line in source.split("\n"):
		number += 1
		var quote := ""
		var current := ""
		var i := 0
		while i < line.length():
			var ch := line[i]
			if quote != "":
				if ch == "\\" and i + 1 < line.length():
					current += ch + line[i + 1]
					i += 2
					continue
				if ch == quote:
					quote = ""
					if log_depth == 0 and is_sentence(current):
						found.append([number, current])
				else:
					current += ch
				i += 1
				continue
			if ch == "#":
				break
			if ch == "\"" or ch == "'":
				quote = ch
				current = ""
			elif log_depth > 0:
				if ch == "(":
					log_depth += 1
				elif ch == ")":
					log_depth -= 1
			else:
				var opener := _log_opener_at(line, i)
				if opener != "":
					log_depth = 1
					i += opener.length()
					continue
			i += 1
	return found

## The log call's opener (`print(`, `Telemetry.note(` ...) that starts at `at` in `line`, or "".
## A name that merely ends in one (`reprint(`, `_assert(`) is not it.
static func _log_opener_at(line: String, at: int) -> String:
	if at > 0:
		var before := line[at - 1]
		if before == "_" or before == "." or before.to_lower() != before.to_upper() \
				or before.is_valid_int():
			return ""
	for opener in ["print(", "push_warning(", "push_error(", "printerr(", "print_rich(",
			"assert(", "Telemetry.note(", "trace.note(", "_trace.note(", "_the_trace().note(",
			"event.trace.note(", "_note("]:
		if line.substr(at, opener.length()) == opener:
			return opener
	return ""

## Whether a quoted string is a sentence in the sense this suite's doc gives.
static func is_sentence(text: String) -> bool:
	for prefix: String in _NOT_A_SENTENCE:
		if text.begins_with(prefix):
			return false
	var words := text.split(" ", false)
	if words.size() < 2:
		return false
	for i in words.size() - 1:
		var run := 0
		var longest := 0
		for ch in words[i]:
			if ch.to_lower() != ch.to_upper():
				run += 1
				longest = maxi(longest, run)
			else:
				run = 0
		var next: String = words[i + 1]
		var starts_word: bool = next[0] == "%" or next[0].to_lower() != next[0].to_upper()
		if longest >= 2 and starts_word:
			return true
	return false

static func _scripts_under(directory: String) -> PackedStringArray:
	var scripts := PackedStringArray()
	var dir := DirAccess.open(directory)
	if dir == null:
		return scripts
	for file in dir.get_files():
		if file.ends_with(".gd"):
			scripts.append(directory.path_join(file))
	for child in dir.get_directories():
		scripts.append_array(_scripts_under(directory.path_join(child)))
	return scripts

## The allow-list entry that covers `path`, or "".
static func _allowed_file(path: String) -> String:
	for prefix: String in _ALLOWED_FILES:
		if path.begins_with(prefix):
			return prefix
	return ""

func _test_a_sentence_is_found_and_a_name_is_not(t) -> void:
	t.check(is_sentence("Day %d of %d"), "a format string with words in it is a sentence")
	t.check(is_sentence("press a button to begin"), "a lowercase line is a sentence")
	t.check(is_sentence("The end."), "two words and a full stop is a sentence")
	t.check(not is_sentence("move_left"), "an action name is not")
	t.check(not is_sentence("res://scenes/main.tscn"), "a resource path is not")
	t.check(not is_sentence("ui/pause"), "an atlas key is not")
	t.check(not is_sentence("%d"), "a bare format is not")
	t.check(not is_sentence("Silence."), "a single word is a name to this rule, caught by a person")
	t.check(not is_sentence(""), "an empty string is not")

func _test_a_comment_and_a_log_call_are_not_judged(t) -> void:
	var source := "var a := \"Plain words here\"\n" \
			+ "# a comment with \"quoted words in it\"\n" \
			+ "var b := 1 # \"and another trailing\"\n" \
			+ "print(\"a log line\")\n" \
			+ "push_warning(\"another log line\")\n" \
			+ "Telemetry.note(\"kind\", \"a run log note\")\n" \
			+ "var c := \"Second sentence here\"\n"
	var found := sentences_in(source)
	t.check(found.size() == 2 and found[0][0] == 1 and found[1][0] == 7,
			"only the two plain strings are found, on lines 1 and 7 (found %s)" % [found])

func _test_a_log_call_hides_only_its_own_arguments(t) -> void:
	var probe := sentences_in("print(\"x\"); _say(\"Walk faster now please\", 1.0)\n")
	t.check(probe.size() == 1 and probe[0][1] == "Walk faster now please",
			"a text after a log call's closing paren on the same line is still judged (%s)" % [probe])
	probe = sentences_in("var shown := \"Two words\" if ok else \"no log here\"; print(\"a log line\")\n")
	t.check(probe.size() == 2, "texts before a log call on its line are judged too (%s)" % [probe])

func _test_a_log_call_over_several_lines_is_skipped_to_its_end(t) -> void:
	var source := "push_error(\"first line of it (not) \"\n" \
			+ "\t\t+ \"second line of it\"\n" \
			+ "\t\t+ str(some_call(1)))\n" \
			+ "var shown := \"Words after it\"\n"
	var found := sentences_in(source)
	t.check(found.size() == 1 and found[0][0] == 4,
			"a call that runs over three lines ends where its parens close (found %s)" % [found])
	t.check(sentences_in("var reprint := \"a name with words\"\n").size() == 1,
			"a name that ends in a log call's own is not a log call")

func _test_the_allow_list_names_only_paths_that_exist(t) -> void:
	for prefix: String in _ALLOWED_FILES:
		var exists := DirAccess.dir_exists_absolute(prefix) or FileAccess.file_exists(prefix)
		t.check(exists, "the allow-list's %s exists, so no entry outlives its file" % prefix)
	for path: String in _ALLOWED_LITERALS:
		t.check(FileAccess.file_exists(path), "the allow-list's %s exists" % path)

func _test_no_sentence_is_quoted_outside_the_catalogue(t) -> void:
	var scripts := _scripts_under("res://src")
	t.check(scripts.has("res://src/ui/texts.gd"), "there were scripts to scan (%d), `Texts` among them"
			% scripts.size())
	var used_files := {}
	var used_literals := {}
	for path in scripts:
		if path == "res://src/ui/texts.gd":
			continue
		var hits := sentences_in(FileAccess.get_file_as_string(path))
		var covered := _allowed_file(path)
		if covered != "":
			if not hits.is_empty():
				used_files[covered] = true
			continue
		var allowed: Dictionary = _ALLOWED_LITERALS.get(path, {})
		for hit in hits:
			if hit[1] in allowed:
				used_literals["%s|%s" % [path, hit[1]]] = true
				continue
			t.check(false, "%s:%d quotes \"%s\" -- a text the player reads goes in `Texts` "
					% [path, hit[0], hit[1]]
					+ "(src/ui/texts.gd), and a developer readout in this suite's allow-list")
	for prefix: String in _ALLOWED_FILES:
		t.check(used_files.has(prefix), "the allow-list's %s still shields a sentence -- drop it" % prefix)
	for path: String in _ALLOWED_LITERALS:
		for text: String in _ALLOWED_LITERALS[path]:
			t.check(used_literals.has("%s|%s" % [path, text]),
					"the allow-list's \"%s\" in %s is still quoted there -- drop it" % [text, path])

func _test_the_catalogue_holds_what_the_screens_say(t) -> void:
	t.check(Texts.TITLE_NAME == "Nappy", "the title's name is the catalogue's")
	t.check(Texts.DAY_BRIEF.size() == Tuning.RUN_LENGTH_DAYS,
			"there is a brief for every day of the run")
	for day in Tuning.RUN_LENGTH_DAYS:
		t.check(Texts.DAY_BRIEF.has(day + 1), "day %d has a brief" % (day + 1))
