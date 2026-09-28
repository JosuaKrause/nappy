# sunny-wombat — A multi-sentence text breaks at a sentence end · built 2026-09-27

*([sandy-marten](../playtests/2026-09-27-sandy-marten.md), statements 1 and 2: "the newline comes
after the period" · "the newline goes after park"; asked whether every sentence gets its own line
or the break falls only where the text must wrap, the player chose the latter: "in the above example
the first two sentences were on the same line")*

**Built (PR #419).** `SentenceLines.break_for_label()` (`src/ui/sentence_lines.gd`) breaks a text
too wide for its label at the sentence end that balances the two lines best, recursing if a half is
still too wide, and hands a single long sentence back to the label's own word wrap. A sentence ends
at `.`, `?` or `!` followed by a space or the end, so "0:10." ends one and "1.5" does not. Widths are
measured with the fallback font at the label's own size against its `custom_minimum_size.x`, so the
day summary's title, note and body and the pause screen's body got the 820px the brief already had.
It covers the day summary's title, the day briefs (day 7's hand-typed break is gone), the resumed-day
note, the endings, the finale body and brief, and the pause screen. `tests/test_sentence_lines.gd`
pins both of the player's examples in the real scenes. No still: no dev flag ends a day on crying or
opens day 1's brief. The HUD's task line is still open, left for after PR #414.
