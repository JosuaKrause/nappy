# Deny a push whose refspecs come from xargs input

Make the GitHub write guard refuse a `git push` invoked through xargs, because xargs input
can supply refspecs the hook does not see. Cover both the supplied placeholder pipeline and
stdin-file case, and representative option/wrapper forms, using hook JSON only. Never run
the candidate pushes. Preserve normal opt-in branch-push prompts, wrapped identity behavior,
readable xargs read commands and the Codex adapter's always-refuse interpretation.

Keep detection bounded and consistent with the existing tokenization/wrapper rules. Record
the conservative false denial of ordinary xargs pushes and any remaining scope limits. Do
not redesign the parser into a security boundary, change game/save code, or fix the old
arithmetic syntax that the source review explicitly leaves outside its requested changes.
Verify meaningful regressions against the old guard, the hook suite, adapter integration
as appropriate, lint and CLI requirements if tools change. Root removes this item and files
its decision in the implementation PR before independent review. No local full game suite.
