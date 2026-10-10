# The trailer plays on GitHub, or is a plain link

GitHub strips an embedded YouTube player from a README, so a YouTube video cannot play in
place there. **A video plays in place on GitHub only as a GitHub-hosted attachment**: an MP4
uploaded into an issue, pull request or comment yields a `github.com/user-attachments/assets/…`
address, and that address on a line of its own in the README renders a player. The upload limit
depends on the account's plan, and **committing** says the bots' installation tokens cannot
upload attachments, so the upload is the player's, through the browser.

So the item has two outcomes, and the player picks: **with an uploaded attachment**, the README
shows the attachment's player where the thumbnail is now and keeps one plain text link to
YouTube; **without one**, the thumbnail goes and the YouTube link stays a plain text link. In
both, the thumbnail image is removed, and the logo still links to the game
(`https://nappy.josuakrause.com/`). The question is open until the player answers it; the plain
link can land first, since it is what both outcomes share.

**Proposed, not asked for:** the attachment is the cut rendered with smooth turns
([mossy-hawk](../2026-10-10-mossy-hawk/README.md)), so it is uploaded once.
