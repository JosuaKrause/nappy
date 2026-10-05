**`tools/goatcounter.sh` prints influenced ÷ seen per event type, by day**, the reading the
player asked for ("mostly I'm interested in the ratio of interacted/seen"), beside the seen count
itself, so how often an event appears and whether players avoid it or ignore it read off one table.
*Proposed, not asked for:* the readout is a flag of the script's own (it is the one way the
repository reads GoatCounter, and a question it cannot answer gets a new flag there), it also prints
the off-screen influences as their own column, and the ratio is left blank rather than divided when
nothing was seen. Its `--help` and the **using-tools** catalogue row say what the flag prints.
