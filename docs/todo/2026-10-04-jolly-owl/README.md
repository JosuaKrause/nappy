priority: now

# jolly-owl — The zzz stays just above her walking south · filed 2026-10-04

[freckled-goose, the zzz walking south](../../playtests/2026-10-04-freckled-goose.md) files inbox
#545, with two phone screenshots in
[freckled-goose-zzz-south-2026-10-04](../../evidence/freckled-goose-zzz-south-2026-10-04/README.md):

> Look at the zzz placement here. When going south the zzz jumps up a full stroller gap above the player
> It should stay over the player without extra gap
> Like in the other directions
> (in the other other directions it's above the stroller but since going south the stroller is below the player it should be positioned above the player instead)

**Asked for:** walking south, where the pram is below her on screen, the baby cue (the zzz and the
louder cues in the same place) sits just above her head, with the same gap it keeps above the pram
in the other facings; no extra stroller-length gap.

**What exists.** `Stroller._draw_baby_cue()` draws the cue at the pram's offset lifted by
`baby_cue_lift()`: `BABY_CUE_LIFT` (36px) above the pram's ground point in every facing but one,
which clears the pram's own art (about 30px tall) by about 6px. On due south (the pram in her own
column, facing down, `PRAM_SOUTH_DISTANCE` 9px below her feet) the lift is `BABY_CUE_LIFT +
FIGURE_HEIGHT` (36 + 46 = 82px) above the pram, so the cue sits about 73px above her feet, roughly
her own height above her head. `baby_cue_aside()` steps the cue sideways when the pram shares her
column and a danger mark is up over her, so the cue that ends a day never shares a column with the
baby's (M32, the cues mean now; the lift came with M39).

**Proposed, not asked for:** on due south, the cue measured from her rather than from the pram,
with the same clearance over her head (`FIGURE_HEIGHT`, 46px) that the other facings keep over the
pram's art: about 6px clear, so about 52px above her feet, about 21px lower than now. The step aside
when a danger mark is up stays as it is.
