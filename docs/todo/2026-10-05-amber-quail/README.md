priority: next

# amber-quail — An order-dependent test leak in a 4-shard run · filed 2026-10-05

[feathery-lynx](../../playtests/2026-10-05-feathery-lynx.md) files inbox #583. The band `next` is
the player's own word, the whole of the note, answering "Should I file it as a queue entry, and in
which band? I'd suggest next.":

> next

**What fails.** A local full run of the suite in four shards fails four checks, each of which
passes when its suite runs alone, so a suite run earlier in the same shard leaves state behind:

- `test_frame_record`: "a played frame is kept";
- `test_invincible`: "and excitement rises too, against the same source";
- `test_orientation`: its two rotated-touch checks.

**How to reproduce.** `./tools/test.sh --shard 4/4` on `main`; then each of the three suites alone
(`tools/test.sh frame_record`, `tools/test.sh invincible`, `tools/test.sh orientation`) passes. CI
splits the suite eight ways, a split that never hits it, so `main` stays green and nothing in CI
shows it. Two agents found it independently, on PRs #565 and #567.

The item is `find-the-leak.md`.

**Proposed, not asked for:** the fix goes where the state is left, in the leaking suite or the
shared state it sets, rather than in the failing suites resetting what they read; the alternative
is the smaller patch of resetting it at the top of the three failing suites, which leaves the next
suite put after the leak to fail the same way.

M100 (small, real, and nobody's) holds a leak of the same shape with a known cause,
`test-finale-gd-leaves-gamestate-escape.md`: `test_finale.gd` leaves `GameState.escape_section`
set, and `test_resistance.gd` run after it in one process fails three checks. Whether the two share
a cause is not known.
