# The trailer checks its disk headroom like the other capture tools

`tools/lib_disk_headroom.sh` holds the measured estimates and the preflight, and seven tools
refuse a batch the volume cannot hold ([the record](../../decisions/2026-10-03-teal-ibis-2.md)).
`tools/trailer.sh` does not check yet: before rendering, it checks `record-second` times the
summed shot seconds against its frame directory, and `import` before its atlas repair, and
`tools/test_disk_headroom.py` gains a trailer case. The record/trailer fixture in
`tools/test_cli_help.py` already copies `tools/lib_disk_headroom.sh`.
