# Playtest dotted-wombat — A run side chosen on the title, smooth scripted turns, the README's trailer link, and a review of the release's PRs

2026-10-10.

The player wrote the three notes below in one message to the orchestrating session, which
captured them into the inbox, and closed the message with:

> the above items are all "now"

## #630 — the run button, then the side chosen on the title

The note on [issue #630](https://github.com/JosuaKrause/nappy/issues/630), labelled
`queue_now`, captured from an earlier session:

> did you merge and cut a release? let's fix the run button by making any tap on the opposite side a run if the original side is still holding down the direction

Draft pull request #631 ("Let an opposite-side touch run beside held steering") was building
that note when the player wrote, on 2026-10-10, words appended to the same note:

> There is currently 631 in flight but I changed my mind. Let's do the following instead:
> we don't allow switching joystick and run key. the decision is mad on the title screen.
> the joystick select buttons move to where the joystick buttons will be. selecting the left one
> will make the left side permanently joystick and the right side permanently run button (permanently for the sitting).
> vice versa on the right side. the tap to play button goes in the center between both.
> this all makes the logic to define how each button works easier. and we can even increase the influence zone
> of the joystick (instead of splitting the in middle we can move it closer to the run button; although I wouldn't go
> all the way). also decrease the deadzone of the joystick (which makes the player stop) smaller/tighter and
> make sure swiping over it but landing outside of it correctly keeps the player moving in the
> direction of the final position.

**Filed as leafy-marten, the steering side is chosen on the title, for the sitting.** The
appended words replace the note's first request, so #631 is closed unmerged and the
opposite-side tap is not built.

## #632 — review again every PR since the last minor release

The note on [issue #632](https://github.com/JosuaKrause/nappy/issues/632), labelled
`queue_now`:

> Your last session got interrupted but all work in flight has been picked up and completed.
> Check all PRs since the last minor release and review them again (note all defects as work items).

**Filed as calm-pelican, defects found re-reviewing the PRs since v0.25.0.** The last minor
release is v0.25.0, whose own commit is PR #539.

## #633 — smooth turns in a movement script, and the README's trailer

The note on [issue #633](https://github.com/JosuaKrause/nappy/issues/633), labelled
`queue_now`:

> regarding the trailer there are two comments: 1) can we make changing directions more smooth?
> in general when running a movement script we should have a smooth option where west 1s north 1s
> has a movement in 270 (left) then gradually going to 0 (north) in a way that the exact horizontal
> position ends up being the same as with the abrupt version (in the west north case; what I mean is they should
> end up in the same exact place no matter whether smooth is on or off). for the trailer I would want
> smooth to be on then 2) the embedding of the video in the readme only works partially.
> I always go to youtube. I want to play it from inside the site. If that is not possible we need
> to change the link anyway. then we won't need a thumbnail either anymore and can make it
> a normal link. thumbnail and logo are currently next to each other (they're almost the same) and
> redundant. clicking on the logo should still go to the game

**Filed as mossy-hawk (comment 1), a movement script turns smoothly and ends where the abrupt
one does, and frosty-egret (comment 2), the README plays the trailer, or links it plainly.**
