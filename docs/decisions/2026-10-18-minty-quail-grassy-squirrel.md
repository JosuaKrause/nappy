# minty-quail — The park cordon's area, tape line and elapsed time become internal, its walk to the gap a local, its gap kept · 2026-11-06


minty-quail's `tests-own-class-members.md`, the underscore pass, for the park cordon's five members
the CI check of test-only members misses, since other classes have members of the same names:
`gap`, `line`, `area`, `elapsed` and `walk_to_the_gap` (record minty-quail-dappled-sparrow). A
public member only its own class and the tests use becomes internal and its tests move to what the
class does outward (curly-rabbit #1098), and one with no reader left is deleted (curly-rabbit
#1095).

**Built.** `area`, `line` and `elapsed` are internal. `walk_to_the_gap` is a local of
`_time_the_close()`, its only reader. The cordon suites read the park's ground off the map and the
tape line grown in from it by half a barrier depth (`tests/cordon_in_the_world.gd`), held to the
world by the existing check that tape bodies cover the whole edge, and they time the close by the
clock they tick.

**Kept public.** `gap`, beside `last_gap`: the sweep checks the chosen gap's stretches against the
map, and the pram and slow-leaver tests stand her before the gap and need its tiles, while the world
shows the gap only once the tapers meet at it, by which time its stretches are taped. Its reason is
a doc comment on the variable rather than a `[kept]` line, since the CI check counts other classes'
`.gap` reads as game readers and refuses the line. Open to overturn.
