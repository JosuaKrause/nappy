## M2 — Baby meters · `feature/baby-meters`

- [x] `baby.gd`: sleepiness + excitement, all rates from `Tuning`
- [x] Baby state machine AWAKE / ASLEEP / CRYING
- [x] Calm-threshold freeze rule
- [x] Running → excitement, idle → sleepiness drain
- [x] Wake-up rule + sleepiness penalty
- [x] `WorldContext` — the only three questions the baby may ask the world
- [x] `hud.tscn`: two meter bars with threshold markers, state + "not settling" hint,
      run header with nerves
- [x] Debug overlay: live incoming/decay/net breakdown
- [x] `tests/` harness + `tests/test_meters.gd` (57 checks)
- [ ] Day clock in the HUD — deferred to M6, which introduces the timer

### Deferred out of M2

- [ ] The HUD shows raw numbers. docs/TODO.md open questions asks whether a diegetic-only
      mode (baby face, no bars) should ship alongside. Revisit after M6 playtesting.
