# silver-marten — The trailer: the carried zzz over her head, the charging dog held, a guard who never gives up · 2026-10-18 · not from an entry


The player, before the trailer was re-rendered: "The zzz when carrying is not consistently over the
parent's head. It moves around wildly. The dog in the charging scene suddenly disappears. We need to
turn off despawning for recording that trailer segment" (minty-lemur #778). Later: "for the trailer,
just use a charging guard instead of one that gets triggered by proximity"; asked whether the chase
cut could have her walk first since running shakes the guard off after 0.35s, "have him rigged to not
give up"; after the re-render, "The zzz is still buggy. It's floating way too high (gap that the
stroller would take)", then of the stills sheet "The bottom row is correct (your picture)", and of the
zzz's step beside a warning mark "A: 34px, as built" (all minty-lemur #778).

**Built (PR #780).**
- **The carried cue is a game fix, not a recipe one:** `Stroller.baby_cue_lift()` lifted the cue over
  her head only walking south and `baby_cue_aside()` stepped it to whichever shoulder she faced, so
  while carrying it sat at her chest and swapped sides on turns. Carrying, it now keeps one height and
  one fixed shoulder on every facing.
- **Recipe options, refused on rows they cannot reproduce:** `hold` keeps a departing pursuer drawn
  (the dog), `charging` starts a waiting pursuer already set on her, `relentless` keeps a pursuer from
  giving up for the scene. The chase shot has her run the whole cut with a charging, relentless guard
  110 to 150px behind her. No `src/events/` edit.

**Built (PR #790).** Carrying, the cue sits `FIGURE_HEIGHT + (BABY_CUE_LIFT - PRAM_ART_HEIGHT)` (52px)
above her feet on every facing, 6px over the tallest carrying sprite (measured from the atlas: the
mother 45px, the father 46px), where #780 had put it a pram's height higher (82px). Beside a warning
mark it keeps the 34px shoulder step, beside the mark at the same height with a 3px gap, which the
player chose over a 56px step. `tests/test_danger.gd` pins 52px on all eight facings.

The trailer was re-rendered from `main` at `bc8adc1d` (`build/trailer/2026-10-18b/`, with a 9.4 MB
copy for GitHub uploads).
