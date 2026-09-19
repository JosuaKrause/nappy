# jq -R -s -f compare_workloads.jq workload-before.log workload-after.log
def rows_without_timing:
  [.runs[] | {day, repetition, mismatches, samples: [.samples[] | del(.[1])]}];
def stats:
  sort as $values | length as $n |
  {samples: $n, p50_usec: $values[($n * 0.50 | ceil) - 1],
   p95_usec: $values[($n * 0.95 | ceil) - 1],
   p99_usec: $values[($n * 0.99 | ceil) - 1], max_usec: $values[-1]};
split("\n") |
map(select(startswith("CROWD_COST_JSON ")) | ltrimstr("CROWD_COST_JSON ") | fromjson) |
if length != 2 then error("expected exactly one before and one after workload") else . end |
if any(.[]; .schema_version != 1 or .window_simulated_seconds != 6 or
  .warmup_simulated_seconds != 5 or .batch_sweeps != 32 or (.runs | length) != 6 or
  any(.runs[]; .mismatches != 0 or (.samples | length) != 180)) then
  error("workload schema, window or parity check failed") else . end |
if (.[0] | rows_without_timing) != (.[1] | rows_without_timing) then
  error("before/after workloads differ beyond timing") else . end |
{identical_nontiming_rows: true,
 before: [.[0].runs | group_by(.day)[] | {day: .[0].day,
   timing: ([.[].samples[][1]] | stats)}],
 after: [.[1].runs | group_by(.day)[] | {day: .[0].day,
   timing: ([.[].samples[][1]] | stats)}]}
