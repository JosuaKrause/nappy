**The queue gains a `bug` band before `now`**, and, if the player confirms it, an `upnext` band
before `bug`. Everything that knows the bands learns them in one change: `tools/queue.sh` and
`tools/lib_queue.py` (the order and `--check`), `tools/new-name.sh todo --priority`,
`tools/inbox.py`'s `queue_<band>` labels and the GitHub labels themselves (`queue_bug`,
`queue_upnext`), CI's queue checks, and the skills and docs that list the bands (**playtest-feedback**,
**inbox**, `docs/TODO.md`). The filing rule is unchanged: a note from playing is filed `now` unless
the player names another band.
