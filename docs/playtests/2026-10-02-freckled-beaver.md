# Playtest freckled-beaver — The measured ground speedup is small

2026-10-02.

The assistant presents the matched ground experiment for silky-rabbit, spread nearby ground
preparation across frames. It reports an ordinary 60Hz median of 1.190–1.202ms atomic versus
1.067–1.070ms per-region, mixed slow-rate tails, increased steady allocation and drawing cost,
and repeated 15Hz safety catch-ups for the global one-section-total candidate. The short
summary initially shows atomic and per-region only, while the evidence contains all three.

The player asks:

> I see only atomic and per region numbers where is the third case?

The assistant acknowledges the missing summary column and supplies all three cases:

| Ordinary south at modeled 60Hz | Atomic | Global one-section cap | Per-region |
| --- | ---: | ---: | ---: |
| Median | 1.190–1.202ms | 1.088–1.091ms | 1.067–1.070ms |
| p99 | 4.627–5.274ms | 4.310–4.532ms | 4.292–4.441ms |
| Worst sample | 8.710ms | 7.332ms | 7.414ms |

It states that the global cap needs 16 southward and 31 diagonal safety catch-ups per trial
at modeled 15Hz while the other two need none, and adds the third column to the PR summary.
The player assesses the result:

> okay and it didn't really make things much faster

The assistant agrees: the ordinary-route gain is about 0.13ms, slow-rate results are mixed,
and steady costs increase. Smaller work chunks are verified, but the evidence does not
establish a noticeable stutter improvement. The player does not select a different runtime
or cancel the work in this message.
