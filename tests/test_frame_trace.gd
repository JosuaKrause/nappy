extends RefCounted
## Raw intervals retain their own counters; bounded capture and pause gaps cannot hide a hitch.

func run(t) -> void:
	var buffer := FrameTraceBuffer.new(4)
	var counters := PackedInt64Array()
	counters.resize(FrameTraceBuffer.COLUMNS.size() - 4)
	counters[1] = 100
	buffer.append(1000000, 20, 18, counters)
	counters[1] = 900
	buffer.append(1040000, 21, 19, counters)
	counters[1] = 200
	buffer.append(1050000, 22, 20, counters)
	buffer.append(1070000, 23, 21, counters)
	counters[1] = 777
	buffer.append(2070000, 24, 22, counters)
	var report := buffer.report(120.0)
	var rows: Array = report.samples
	t.check(rows.size() == 4 and report.dropped_after_capacity == 1,
		"a full buffer preserves captured frames and counts the omitted tail")
	t.check(buffer._values.size() == 4 * FrameTraceBuffer.COLUMNS.size(),
		"overflow never grows storage")
	t.check(rows[1][0] == 1040000 and rows[1][1] == 21 and rows[1][2] == 19,
		"the slow interval retains its raw timestamp and both engine frame IDs")
	t.check(rows[1][3] == 40000 and rows[1][5] == 900 and rows[2][5] == 200,
		"the slow frame owns its counters rather than the later reporting frame's counters")
	t.check(rows[3][5] == 200, "later input mutation and overflow leave retained counters intact")
	var summary: Dictionary = report.summary
	t.check(summary.intervals == 3 and summary.p50_ms == 20.0
		and summary.p95_ms == 40.0 and summary.p99_ms == 40.0 and summary.max_ms == 40.0,
		"nearest-rank percentiles exclude the anchor and dropped tail")
	t.check(summary.over_60hz_budget == 2 and summary.over_30hz_budget == 1
		and summary.over_refresh_budget == 3, "budget counts use raw intervals and display refresh")
	var segmented := FrameTraceBuffer.new(4)
	segmented.append(1, 1, 1, counters)
	segmented.append(10001, 2, 2, counters)
	segmented.break_interval()
	segmented.append(9999999, 8, 8, counters)
	segmented.append(10019999, 9, 9, counters)
	var segments := segmented.report(-1.0)
	t.check(segments.samples[2][3] == 0 and segments.summary.intervals == 2
		and segments.summary.max_ms == 20.0, "pause and title gaps cannot become measured stalls")
	t.check(segments.summary.refresh_budget_ms == 0.0
		and segments.summary.over_refresh_budget == 0, "unknown refresh does not invent a budget")
	var empty := FrameTraceBuffer.new(1).report(60.0)
	t.check(empty.samples.is_empty() and empty.summary.max_ms == 0.0,
		"a run with no rendered samples explicitly exports an empty report")
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(report))
	t.check(decoded.samples[1][3] == 40000 and decoded.samples[1][5] == 900,
		"export round trip retains frame attribution")
