priority: now

# downy-lark — Leaving a gatehouse, she stands still · filed 2026-10-10

[azure-puffin](../../playtests/2026-10-10-azure-puffin.md), inbox #667:

> oh and there is a bug when leaving the guard huts that the player keeps moving in the previous
> direction. let's reset the movement to 0 when leaving so the player has a choice.

The guard huts are the region doors' gatehouses: walking into one holds her inside for
`Tuning.CHECKPOINT_DETAIN_SECONDS`, hidden, and lets her out on the far side (`docs/MECHANICS.md`,
the hold). The work is [stand-still-on-leaving.md](stand-still-on-leaving.md).
