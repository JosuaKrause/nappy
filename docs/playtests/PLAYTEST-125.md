# Playtest 125 — A poster tear draws its pursuit from a marble bag

2026-09-23. Said in conversation, unprompted, while M186 (the building fronts redrawn) and M187
(a closure lies across the street it closes) were in review. No run was played. It amends the
open M180 item "She tears a poster down by pushing against its wall", whose last sentence reads:
"A tear has a small chance of a pursuer: a `police_patrol` sent toward her from off screen under
the lead its row already owes, starting at one tear in ten, and never on the first tear of a run."

## What the player said

> "when choosing whether ripping off a poster causes a pursuit let's try a method called marble
> bag. you randomly place "marbles" in a bag with the desired probability. then you draw the
> marbles when you need a random outcome (in this case whether a pursuit happens or not). if the
> bag is empty you fill it again. this has the advantage over a regular random number generator
> that it has the desired probability but feels "fair". a standard rng could produce outcomes
> like xxxxxyxy even if the probability is 50/50 for x and y a marble bag would guarantee that in
> a stretch of the size of the bag the probability is exactly 50% for each. furthermore with a
> "pre"-bag we can guarantee that the first n poster rips have no pursuit (we initialize the
> marble bag with n "no pursuit" marbles; once the first bag is empty we fill it with the correct
> amount of pursuit/no pursuit marbles; eg let's say we want the first 3 to be guaranteed to be
> no pursuit so we initialize the first bag with [nnn] then the second bag will get [nnnnnnnnpp]
> marbles for a 20% pursuit chance). for now let's use this technique only for poster rips and
> nothing else"

> "to be clear you fill the bag with a fixed set that yields the desired distribution (eg. 2
> pursuits and 8 non-pursuits for 20%) and then you randomly draw from the bag (and remove the
> marble)"

## The statements

1. **Whether a tear brings a pursuer is drawn from a marble bag**, not rolled: the bag is filled
   with a fixed set of marbles in the desired proportion — for 20%, two "pursuit" and eight "no
   pursuit" — and each tear draws one marble at random and removes it. An empty bag is filled
   again with the same set.
2. **Why:** it has the desired probability and feels fair. Over any one bag the share is exact,
   where an ordinary random roll can run long streaks at the same odds.
3. **A pre-bag guarantees the first tears bring no pursuer**: the first bag holds only *n* "no
   pursuit" marbles, and every bag after it holds the ordinary set. In the player's example the
   first bag is `[nnn]` and each later one `[nnnnnnnnpp]`, so the first three tears are safe and
   the chance after that is 20%.
4. **Only poster tears use the marble bag for now**, nothing else in the game.
