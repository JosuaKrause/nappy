**The queue gains a `bug` band before `now`, and an `upnext: true` marker that prints an entry
first whatever its band.** `queue.sh --check` accepts the marker only in the opening block. Everything that knows the bands learns them in one change: `tools/queue.sh` and
`tools/lib_queue.py` (the order and `--check`), `tools/new-name.sh todo --priority`,
`tools/inbox.py`'s `queue_<band>` labels and the GitHub label itself (`queue_bug`), CI's queue checks, and the skills and docs that list the bands (**playtest-feedback**,
**inbox**, `docs/TODO.md`). The filing rule is unchanged: a note from playing is filed `now` unless
the player names another band.
