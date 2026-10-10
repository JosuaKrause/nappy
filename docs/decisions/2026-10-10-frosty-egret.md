# frosty-egret — The README plays the trailer in place · 2026-10-10


[Dotted-wombat](../playtests/2026-10-10-dotted-wombat.md), inbox #633, comment 2:

> the embedding of the video in the readme only works partially. I always go to youtube. I want
> to play it from inside the site. If that is not possible we need to change the link anyway.
> then we won't need a thumbnail either anymore and can make it a normal link. thumbnail and logo
> are currently next to each other (they're almost the same) and redundant. clicking on the logo
> should still go to the game

This reopens [freckled-elk](2026-10-08-freckled-elk.md), which linked YouTube's thumbnail to the
video because GitHub's Markdown filters an iframe player.

**A GitHub attachment plays in place.** The player uploaded the under-10MB cut rendered with
smooth turns ([mossy-hawk](2026-10-10-mossy-hawk.md)) into a pull-request comment (inbox #650 in
[mossy-beaver](../playtests/2026-10-10-mossy-beaver.md): "the trailer link is in
https://github.com/JosuaKrause/nappy/pull/643#issuecomment-6097675357"), which gives the address
`https://github.com/user-attachments/assets/a8033ef2-cabf-4a4f-b323-3d1bf0dfc0d3`. On a line of its
own in `README.md`, GitHub's rendered README for the pushed branch (`gh api -H "Accept:
application/vnd.github.html" repos/JosuaKrause/nappy/readme?ref=<branch>`) carries it as a
`<video>` element with the attachment as its source, so the trailer plays on the repository's
own page. The attachment was tried first, as the entry asked; the other candidate, a video
committed to the repository, was not needed and keeps the MP4 out of Git history.

**The text link stays and points at the new upload**: "the new youtube link is
https://youtu.be/cTB_woqjSMg". The README reads, under the logo (still linking to the game) and
the opening paragraph: the link "Watch the gameplay trailer on YouTube." and, below it, the player.

**The thumbnail stays gone.** The README already had none when this was built; the entry's
reading, open to correction, was that it goes in both outcomes, since the player called it
"redundant" beside the logo.
