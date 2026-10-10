# The trailer plays on GitHub, or is a plain link

**This reopens [freckled-elk](../../decisions/2026-10-08-freckled-elk.md), the README links the
published trailer.** In [olive-toad](../../playtests/2026-10-08-olive-toad.md), GitHub's
attachment uploader refused the movie for exceeding 10MB, and the player answered "it's fine we
can commit the video / or I upload to youtube" and then supplied the YouTube address; freckled-elk
built the thumbnail linked to YouTube, since GitHub's Markdown filters iframe players. The player
now finds that it "only works partially. I always go to youtube".

What is known: GitHub filters an embedded YouTube player out of a README. What is not yet known,
and is the first thing to settle at pickup: **which route, if any, plays the trailer in place on
GitHub's README page.** The candidates, each checked against GitHub's rendered README for a
pushed branch (`gh api -H "Accept: application/vnd.github.html" repos/JosuaKrause/nappy/readme?ref=<branch>`
shows what survives the filter) rather than assumed:

- **A GitHub attachment** (a `github.com/user-attachments/assets/…` address on a line of its own),
  for a cut re-encoded under the 10MB limit the uploader gave. Only the player can upload one,
  through the browser, since **committing** says the bots' installation tokens cannot.
- **A video committed to the repository**, which the player allowed in olive-toad ("it's fine we
  can commit the video"), referenced from the README in whatever form GitHub renders as a player.

If one plays in place, the README shows that player where the thumbnail is now and keeps one
plain text link to YouTube. If none does, the player's fallback holds: "we need to change the link
anyway. then we won't need a thumbnail either anymore and can make it a normal link". Either way
the logo still links to the game (`https://nappy.josuakrause.com/`).

**Read as, open to correction:** the thumbnail goes in both outcomes, since the player called it
"redundant" beside the logo ("they're almost the same"), though the words tie its removal to the
plain-link outcome.

**Proposed, not asked for:** the video shown in place is the cut rendered with smooth turns
([mossy-hawk](../2026-10-10-mossy-hawk/README.md)), so it is uploaded or committed once.
