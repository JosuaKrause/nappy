**`charging_dog` is warned first and keeps exactly that timing**, on day 3 and wherever else
it arrives from off screen, with walking still losing the chase. A test fails if the day-3
timing moves. The resistance's own `robber_giving_chase` and `van_guard_giving_chase`
(PR #362, M137) come off the "not warned first" exception the same way and are warned first to
the same gold timing; a test fails if either stops being warned before it can reach her.
