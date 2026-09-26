## Gotchas learned in M18

- **Cutting the day tests the tests.** Every M14 balance claim is written as a relationship
  over `day_length()`, and halving the day is exactly the change those relationships exist
  to survive. They did: nothing needed its shape changed, and the one that pushed back —
  "a whole day of street walking still makes real progress" — pushed back correctly, which
  is why street gain went *up* while the day got shorter.
- **A shorter day is a faster suite.** `tests/test_balance.gd` steps a real `Baby` through
  fourteen days at 1/60s; it went from 94s to 27s for free.
