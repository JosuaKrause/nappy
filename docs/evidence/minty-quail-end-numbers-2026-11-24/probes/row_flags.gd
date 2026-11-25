extends RefCounted
## Evidence copy (minty-quail end remeasure, N8): prints `FLAGS id ends_the_day pursues waits hunts_for_her`
## for every catalogue row, so the RV lines of placement_rows.gd can be sorted by what a row does to her.
## Copied into tests/probes/ of the scratch tree uncommitted to run; not part of the repository's probes.

func run(t: TestRunner) -> void:
	for def: EventDef in CatalogueRows.every():
		print("FLAGS %s %d %d %d %d" % [def.id(), int(def.ends_the_day()), int(def.pursues()),
				int(def.waits_for_her()), int(def.hunts_for_her())])
	t.check(true, "flags printed")
