# minty-quail — The lane strategies ask where their mover is, and tell it to move, through the lane · 2026-11-10

**The ask.** "never read fields directly. always read through a method" (inbox #1173 in
gray-dolphin). The narrow lane interface (`LaneMover.Lane`, the record minty-quail-brisk-lark) left
the car and walker strategies making 49 calls on 11 of `LaneMover`'s underscore methods; this is
the bullet of `field-reads.md` that turns them into questions and events named for what is asked
and what happens.

## What was built

- **Neither strategy calls an underscore method of its mover** (`car_strategy.gd`,
  `walker_strategy.gd`); `rg -n '_mover\._[a-z_]+\(' src/crowd` prints nothing.
- **Seven questions on `Lane`**: `position_along()`, `position_across()`, `tile_ahead()`,
  `street_is_shut_at(tile)`, `stands_on_a_street()`, `is_out_of_view()` and `has_left_the_field()`.
- **Five events on `Lane`**: `be_placed_along(at)`, `be_placed_at(point)` (the walker going into a
  checkpoint hut), `be_placed_on_its_lane_at(along)` (coming out of it),
  `turn_round_where_it_stands()` and `be_recycled()`. `_set_cross()` has no event of its own: both
  its calls were halves of the walker's two pairs.
- **All eleven underscore methods stay**, private, because the mover's own code still calls each.
  No existing event carried these changes: `turn_into()`, `enter_a_lane()` and `turn_round_into()`
  change the lane, not where the body stands.
- **The tick is hot**, so `position_along()` and `position_across()` read the mover's own fields
  rather than calling `_along()` and `_cross()`, and three car functions that asked the same
  coordinate twice keep it in a local.

## Parity

Five hashes are the same on `main` at `4789a0c67` and on the head of the code, `d8a6fa3ca`: the
crowd tick's chains (`b856fc27…`), the lane parity lines (`bb35932d…`), the bodies' seed lines
(`a97b0621…`), the excitement fingerprint (`7510c1d0…`) and the events tick sweep's chains
(`bf69e949…`). The lane parity lines are hashed with `tick_median_us` and `agents_median_us` taken
out: they are timings, so the whole lines never match between two runs. The tick's cost was not
measured in this pull request.

## Open to the player's overturn

- **Two probes still call three of the eleven directly**, four calls in all
  (`tests/probes/m100_map_edge_entries.gd`, `m156_car_turns.gd`). The methods stay and those probes
  read eight other underscore members besides, so moving the four calls would not make them comply.
- **The names**, the builder's: the design asked only that they be named for what is asked and what
  happens. `position_along` and `position_across` keep away from the mover's old names, and the
  `be_placed_*` family follows `Lane`'s existing `be_in_junction()`.
