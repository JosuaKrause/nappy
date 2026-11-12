class_name RecordingTrace
extends RunTrace
## **A run's trace for a suite that reads what a component decided**: every line it is handed is
## kept as `"kind text"` in the list it was made over, and written nowhere. A helper, not a suite:
## the runner loads only `test_*.gd`. It is handed in where the game hands a component the run's
## trace (`RunSession`'s, which writes to the run log), so the suite reads the component's own
## account of a decision rather than its state.

func _init(into: Array[String]) -> void:
	super(func(kind: String, text: String) -> void:
		into.append("%s %s" % [kind, text]))
