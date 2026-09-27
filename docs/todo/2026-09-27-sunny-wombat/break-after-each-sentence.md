**Every multi-sentence text on a screen breaks its line after each sentence's period**: the day
summary's title (a lost day's reason with its time), the day briefs, the finale brief, the endings,
the pause screen and the marks' task line at the bottom left. One helper does it rather than
`\n` typed into each string, so a new text gets it too, and a sentence too long for the width
still wraps inside itself. A test runs the helper over every such text. Stills of the crying
summary and one brief.

**Proposed, not asked for:** the task line at the bottom left is included, so a two-sentence mark
("Cross at this district door. See if they let you through.") shows as two lines.
