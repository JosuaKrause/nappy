# jq -f six_seconds.jq TRACE.json: nearest-rank statistics over an equal raw-clock window.
if .schema_version != 1 or (.samples | length) < 2 then
  error("expected nonempty version-1 raw frame trace")
else . end
| .samples[0][0] as $start
| if .samples[-1][0] < $start + 6000000 then
    error("trace does not cover six seconds after its first anchor")
  else . end
| [.samples[] | select(.[0] <= $start + 6000000)] as $window
| if ([$window[] | select(.[3] == 0)] | length) != 1 then
    error("comparison window contains an active-play gap")
  else . end
| [$window[] | select(.[3] > 0) | .[3]] | sort as $v
| {file: input_filename, intervals: ($v | length),
   p50_ms: ($v[(($v | length) * 0.50 | ceil) - 1] / 1000),
   p95_ms: ($v[(($v | length) * 0.95 | ceil) - 1] / 1000),
   p99_ms: ($v[(($v | length) * 0.99 | ceil) - 1] / 1000),
   max_ms: ($v[-1] / 1000),
   over_60hz_budget: ([$v[] | select(. > 1000000 / 60)] | length)}
