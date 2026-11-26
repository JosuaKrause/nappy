# spry-kestrel — A dev flag plays the escape building's flashes with a least gap · 2026-11-25

The player asked to see the escape building's window flashes with and without a least gap before
judging (inbox #1787 in gentle-beaver); their earlier words ask the flashes to match the apartment
building's (minty-lemur #785). The city's flashes keep `FlashRhythm.LEAST_GAP` (0.4 s); the
building keeps the player's own timing, where 6.3% of 20,000 simulated walks hold four flashes in a
second (`tools/decisions.sh snowy-goose`).

**What was built.** `--building-flash-gap S` (web: `?debug=1&buildingflashgap=S`, in the open
bundle) sets the least gap between two starts of the building's flashes, `0` meaning none and the
default. `InteriorScene.use_flash_gap()` takes it from `RunConfig.building_flash_gap()`; a bang or
a far flash that comes inside the gap waits for it, as the city's do, and the far flashes' stream
is drawn exactly as before, so a seed replays the same waits. With no gap the building behaves as
it did. A bad value (not a number, or negative) is refused whole with a warning and plays no gap.

**Not decided.** Whether the building keeps its own curve or takes the city's limit: the review
item of the same name asks the player after they have played both.

**Proposed, not asked for:** the flag's name and its web twin (the filer's), and that a held-back
flash waits rather than is dropped (the city's behavior).
