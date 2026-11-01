# azure-panda — A review's text goes to the API with capital -F · 2026-11-01

Note #431 ([minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md) statement 2, filed as it stands at the player's word "file it as is"; band `later` by "later sure"): a body file goes to the API with
capital `-F` (`-F body=@file` sends the file's contents; lowercase `-f` sends the literal text `@file`).
Twice on 2026-09-27 an agent posted `@file` as a review or comment body and had to edit it. In the queue
review the player asked "if it's only one line shall we just do it now?" (inbox #930 in tiny-lark) and
answered "yes" to doing it in the filing pull request (inbox #931 in tiny-lark).

**Built.** The **pr-review** skill, which tells a reviewer how to post, says that a review's text is
written to a file first and passed with capital `-F`, with the reason; **using-tools** already said it.
The wording is the session's, not the player's. Flagged to the player as a skill change in the filing
pull request.
