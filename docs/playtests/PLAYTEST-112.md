# Playtest 112 — The stutter is gone, and the man shouting costs nothing to walk beside

2026-09-20. Played on the desktop build of v0.14.0, the release that ends M171, build-time
atlases replace individual textures. The run is
`docs/evidence/m174-yeller-beside-2026-09-20/`.

## What the player said

> "I feel like the stuttering is gone (so it was always what I predicted -- a proper atlas
> implementation solved it). did the numbers for the yeller change? I can easily walk next to
> him for an extended amount of time without any real penalty. or maybe the halo calculation
> changed? he gets deep red but my bar doesn't move up much. it was supposed to indicate the
> actual amount I receive over a time window"

## What the repository and the run say

**Nothing about him changed in the release.** Between `v0.13.1` and `v0.14.0` no number in
`event_catalogue.gd` or `tuning.gd` differs and `excitement_halo.gd` is untouched;
`homeless_yeller`'s intensity has been 14 since 2026-08-28.

**The halo and the bar measure different things.** The halo is the gross excitement that
landed from one source over the last five seconds (`ExcitementHalo.WINDOW`, which is
`Tuning.EXPECTED_IMPACT_HORIZON`), traced back from the meter's own sum, and it is full red at
40 points (`Tuning.EXPECTED_IMPACT_POINTS`, 0.4 of the meter). The bar is that, less the decay
she earns by walking: `Tuning.EXCITEMENT_DECAY_WALKING`, 6.0 a second, 30 points over the same
five seconds.

**His numbers, at arm's length.** Intensity 14 inside `inner_radius` 45px, on a five-second
pulse that runs between a quarter and the whole of it (`current_intensity()`'s
`0.25 + 0.75 × …`), so 3.5 to 14 a second and 8.75 on average: about 44 points land in five
seconds, which is deep red, and walking takes 30 of them back, so the bar gains about 14 —
under 3 a second. With the baby asleep (`SLEEPING_SENSITIVITY` 0.55) about 24 land and walking
takes back more than that: the bar does not move at all. The run shows the trough: 17px from
him, `in 4.6/s (crowd 0.0, events 4.6)`, which is less than walking gives back.

So the halo reports what it was asked to report — *(2026-09-08: "don't derive it from the
source numbers but trace an increase in excitement back to its constituents")* — and what it
reports is not what the bar does while she is walking.

## What is asked for, as statements

1. **The stutter is gone on the desktop with the baked atlases**, by the player's feel. M159,
   a slow frame names the frame that was slow, takes that as its starting point.
2. **Walking beside the man shouting carries a real penalty**, and **a deep red halo means the
   bar is rising.** Which of the two moves — his numbers, what the halo counts, or both — is
   the player's to say.
