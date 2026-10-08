# freckled-elk — The README links the published trailer · 2026-10-08 · not from an entry

[Olive-toad](../playtests/2026-10-08-olive-toad.md), inbox #627, records the request to show
the trailer in the README. After the GitHub attachment uploader rejects the movie for
exceeding 10 MB, the player supplies `https://youtu.be/88nfOmjEcHc` and asks to embed it,
then push, merge and release the patch.

The README links YouTube's thumbnail to that video and includes a text link naming YouTube.
GitHub's Markdown filters iframe players, so a clickable preview is the supported presentation.
The user can watch the published video without a copy of the MP4 entering Git history.
The local approved trailer remains the master; this change does not render or revise it.

The thumbnail endpoint returns a 1280×720 image showing the trailer's title card. Its visible
contents and the exact destination video ID are checked, and the documentation lint and
whitespace checks pass. The request is implemented directly in this documentation PR, so
no unfinished queue item or additional human playtest is created.
