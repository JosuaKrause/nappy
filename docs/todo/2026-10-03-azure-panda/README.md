priority: later

# azure-panda — A file is passed to the API with capital -F · filed 2026-10-03

**The skills say a body file goes to `gh api` with capital `-F`**
([minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 2, note #431, filed as it stands at the player's word: "file it as is"; the
player's words in the note are only "add it as issue", its text is the session's).
`gh api … -F body=@file` sends the file's contents; `-f body=@file` (`--raw-field`) sends the
literal text `@file`. Twice on 2026-09-27 an agent posted `@file` as a review or comment body and
had to edit it. **using-tools** and **pr-review** (which tells a reviewer how to post) say which
flag to use, since writing long text to a file and passing the file is how the write guard wants it
passed; the guard's own deny hint already names `gh api -F body=@file`.

When built, **CLAUDE.md**'s "a skill found wrong is fixed, and the fix is flagged to the player"
applies.

**Proposed, not asked for:** the fix's wording, the session's; and the band `later`. **Asked:** the
note has no band label, and the player has been asked which band it gets.
