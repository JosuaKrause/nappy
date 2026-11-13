priority: bug
upnext: true

# tawny-hedgehog — inbox.py cite writes files when used as a lookup, and doubles a citation wrapped across a line · filed 2026-11-13

From the playtest amber-goose (#1442). The player, after the orchestrator relayed that the Fable reviewer of #1441
ran `tools/inbox.py cite 1432` expecting a lookup, found a file edited, and saw the tool double a citation that wraps
across a line: "schedule a bug fix. remember those get highest priority" (amber-goose #1442). The band is `bug`,
which the player named.

**Read as:** two pieces of work. The bug in `tools/inbox.py cite` is fixed (`cite-on-lookup.md`). And "those get
highest priority" is a standing rule that the orchestrating skill does not yet state: an entry in the `bug` band is
started, reviewed and merged ahead of all other work, an entry the player has put first included
(`bugs-go-first.md`). The `bug` band's place above `now` is already the player's (mossy-ferret #710); what the skill
lacks is that bug work passes the fence of an entry put first, which today only work on how the project is worked on
passes (inbox #1305 in grassy-trout).

Both items are work on how the project is worked on (a project script, a skill), so `upnext: true` is the filer's
proposal on top of the band.
