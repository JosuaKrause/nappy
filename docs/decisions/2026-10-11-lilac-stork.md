# lilac-stork — A bug band above now, and an up-next marker above both · 2026-10-11


[mossy-ferret](../playtests/2026-10-11-mossy-ferret.md), #710: "we need a new band "bug" that has
priority over now. also, maybe something to indicate what to work on next?" and "like "immediately
after the current items are done" next, not the band next". Told that making up next a band would
cost the entry the band it came from, the player took a marker beside the band instead (#713:
"okay let's do that then."). Asked whether notes from playing now default to `bug`: "Only when you
say so".

**Built.** `tools/queue.sh` knows a `bug` band, printed before `now` and, like `now`, newest entry
first; `tools/new-name.sh todo --priority bug` makes one, and `tools/inbox.py` takes a `queue_bug`
label, which exists on GitHub beside the other four bands' labels. An entry's opening block may carry `upnext: true` beside its `priority:` line: every marked
entry prints first, under an `up next` heading, its real band still on its line, unless its `after:`
names an open entry: then it stays behind what it waits on in its band, as M223's order requires,
and only a closed `after:` frees it for the section. Every marked line ends in `[up next]`, in the
full listing and under `--band`. `--check` rejects the marker with another value, repeated, or below
the opening block. The queue move that starts an entry's work drops its marker
(**orchestrating**), and the end-of-session pass drops one left on an entry an open pull request is
building (**session-cleanup**). With no marked entry the output
is as before, and `--band B` prints no heading. `docs/TODO.md` and the **playtest-feedback**,
**inbox**, **committing** and **using-tools** skills list the band and the marker. The filing rule is
unchanged: a note from playing is filed `now`, and no entry is filed `bug` unless the player names
it.

*Open to overturn, chosen by the implementer:* `bug` sorts newest first, as `now` does. The orchestrator
chose, on review, that a marked entry waits behind an open `after:` rather than jumping it.

**Not built:** the filer's proposal (*proposed, not asked for*) that the up next section also name
the entries a live agent is working on. The briefs that would say so live untracked in the main
checkout, and tying a brief to an entry and to an open branch is not reliable offline, which
`--check` must be.

**Verified** by `tools/test_cli_help.sh`'s cases for the order, the heading, `--band bug` and the three
rejections, `tools/test_inbox.py`'s `queue_bug` case, and `tools/queue.sh --check` on the real queue.
