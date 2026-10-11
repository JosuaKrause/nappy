**In Hard Mode a won day gives no nerve back.** `GameState.regain_a_nerve()` (or its caller) gives
nothing when `GameState.hard_mode` is set; a normal run is unchanged. A test wins a day in each mode
and checks the nerves after it. `docs/MECHANICS.md`'s "Nerves" says the regain is a normal run's
only, and "Two modes" carries the player's definition of gameplay beside "hard mode doesn't affect
gameplay -- only restart pacing". Nothing that happens during a day reads `hard_mode`.
