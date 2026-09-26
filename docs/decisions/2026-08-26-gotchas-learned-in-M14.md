## Gotchas learned in M14

- **Pitch balance numbers against the day, not against each other.** The old numbers were
  all mutually consistent and the day was still winnable by circling the block, because
  nothing tied the fill rate to `day_length()`. The two tests that matter now are written
  as `GAIN * day_length(day) < METER_MAX` and `METER_MAX / calm_gain < day_length * 0.6`,
  so lengthening the day cannot quietly make the street sufficient again.
- **Arithmetic is necessary and not sufficient.** Whether a park fills the meter depends on
  whether the crowd pushes it over the freeze threshold, which no data-level test can see.
  `tests/test_balance.gd` stands a real `Baby` in a real city with that day's crowd and
  events. It is what caught that the claim needed checking on all fourteen days, not one.
- **Check the short day.** A calm stretch of 139s looked fine against the 330s day and was a
  stopwatch race against the 264s curfew one. Every balance claim here is measured against
  `day_length(RUN_LENGTH_DAYS)`.
