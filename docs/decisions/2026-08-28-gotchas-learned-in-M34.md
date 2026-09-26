## Gotchas learned in M34

- **A field that is only ever *reached for* is a list wearing a rule's clothes.**
  `obstructs_radius` existed from M5 and was set five times in thirty rows, every time because
  somebody wanted that particular event to block a pavement. Nothing was wrong with any of the five
  and the whole thing was wrong. When a field's value looks like a series of local decisions, ask
  what would decide it for a row nobody has thought about — here it was already decided, in
  `_draw_spread`'s own comment, and had been for four milestones.
- **A lethal radius and a solid body are the same mechanism.** She is stopped
  `obstructs_radius + PLAYER_BODY_RADIUS` from the centre, so on a `hard_fail` event a body that
  reaches the inner radius does not make it unfair, it makes it **never fire** — and nothing
  reports an event that quietly stopped working. It is `validate()`'s job now. The general shape:
  when two systems both measure a distance to the same point, check what happens when one of them
  wins.
- **Check which event a complaint is actually about.** *"I can walk over the robber"* was written
  up as an `alley_robbery` bug, and `alley_robbery` is day 8, alleys only, and both traces end on
  day 4. The man is `homeless_yeller`, with nineteen `near` entries. The write-up's arithmetic was
  wrong as well — nothing stopped her, so her centre reached his and the day ended — and the
  arithmetic only *became* true when he was given a body. A finding named after the wrong row sends
  the next person to the wrong file.
- **A rule that reads `obstructs_radius > 0` may mean two different things.**
  `_something_to_put_in_a_park` refused anything with a body, which meant "nothing that closes the
  ground" while only scaffolding had one and meant "no buskers" the moment everything did — which
  would have emptied the spoiler pool and retired M24 without a test failing on anything but the
  spoil rate. `OBSTRUCTION_A_PARK_CAN_HOLD` is the same rule stated as what it always meant.
- **"It does nothing" can be two complaints in one sentence.** The delivery van did nothing because
  it had no body **and** because it was in a traffic lane the crowd drives straight through,
  blocking a route nobody walks. Fixing either alone leaves *"a still car standing on the road
  doing nothing"* true.
- **A probe that divides inside the loop it accumulates in is off by a factor per seed.** The first
  density run said 1.68 events live around her against a documented 4.79, which reads exactly like
  a regression worth a milestone. It was five seeds' worth of dividing seed one's contribution five
  times. Before believing a number that disagrees with a document, run the same probe against
  `main` — which is the comparison that has to be made anyway.
- **`var x := load(...).instantiate()` does not parse**, and the failure is the quiet one: the
  suite dies at *load* time, prints nothing at all, and `tools/test.sh` sits there. `CLAUDE.md`
  already says a run with no output is an error rather than a slow suite; this is the cheapest way
  to cause one.
