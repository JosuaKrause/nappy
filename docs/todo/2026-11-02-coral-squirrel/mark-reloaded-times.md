# A run resumed from a mid-walk save marks its shown times as inaccurate

**Build:** a save records whether it was written while a day was being walked; a run resumed from
such a save carries a flag, and the times it shows that the lost stretch makes short say they are
inaccurate because of a reload (the player: "indicate that the displayed times are inaccurate due to
reloading", inbox #965 in brisk-pelican). A save written at a day brief carries no flag. Which screens
carry the mark and how it reads come from the player's words; draft pull request #1207 is built on
the orchestrator's pick, and the research goes into it when it resumes after the refactor, as the
entry's `README.md` says (gentle-owl #1240).
