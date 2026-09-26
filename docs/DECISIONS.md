# Decisions

**Every decision is a file of its own, under [decisions/](decisions/).** A file is named
`<date>-<words>.md`, so sorting the folder puts the newest last, and two pull requests never edit
the same record. A decision that closes a queue entry takes the entry's name
(`<date>-<adjective>-<animal>.md`, or `<date>-M210.md` for an entry filed before names). A record
written before the queue was files is named by its date and its heading
(`2026-09-25-M201-a-ci-job-does-not-download-the-evidence.md`), and one milestone number can have
many of those.

**No index is checked in**, since an index every pull request edits is the same conflict again.
`tools/decisions.sh` lists the records by date and searches their titles and their text:

    tools/decisions.sh                  # every record, oldest first
    tools/decisions.sh M129             # every record whose title or text names M129
    tools/decisions.sh spent park       # every record that says both words

**A citation reads "`DECISIONS.md`, M129, a spent park is closed"** wherever it stands — a code
comment, a skill, a doc: a milestone and a record's title. `tools/decisions.sh M129` lists that
milestone's records, titles first, and the title picks one out.

A record says what was true when it was written, with what was measured and what was rejected;
none of it should be read as current. The open work is [TODO.md](TODO.md) and the entries under
[todo/](todo/); what waits on a person is [REVIEW.md](REVIEW.md) and the items under
[review/](review/).
