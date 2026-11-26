# An RC sends no count and keeps a save of its own

The RC export drops `count.js` from the page, `GoatCounterOutbox.may_ever_send()` refuses on a version
that names an RC, and `GameSave` reads and writes a file name of its own for one, so the release
save is never touched. `docs/TELEMETRY.md` states both, and a test row holds each (**telemetry**
and **writing-tests** govern the change).
