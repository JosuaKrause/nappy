**The deny message is built without passing the flagged text as one argument**: cut the quoted text
to about 2,000 characters (which also keeps the message readable), or hand the reason to `jq` on
stdin, the way `tools/test_rules_hooks.sh` builds its payloads. A test with a long multi-byte
flagged text shows a deny. The Codex adapter needs no change unless the hook's output format does.
