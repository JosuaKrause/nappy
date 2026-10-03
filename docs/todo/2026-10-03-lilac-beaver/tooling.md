**Two tools say what they do**
([#454's review](https://github.com/JosuaKrause/nappy/pull/454#pullrequestreview-5400224615),
bouncy-badger, refresh CI shard costs, and
[#440's review](https://github.com/JosuaKrause/nappy/pull/440#pullrequestreview-5400340073),
new-name.sh recognises a used name as taken).

- `tools/test.sh`'s comment on `TEST_SHARD_TIMEOUT_S` says the four-shard plan "tops out at
  ~473s", "comfortably" under the 600 s that kills a local shard as hung. The refreshed cost table
  plans 581 s per shard at four shards (`tools/test.sh --plan`). Point the comment at
  `tools/test.sh --plan` instead of quoting a figure, and raise the default (about 900 s). This was
  raised before #454 merged and left.
- `tools/new-name.sh`'s taken-name check reads "not taken" when anything before `grep` in its
  pipeline fails, even if `grep` matched (`ls` exits 1 on a folder it cannot read). Grep a captured
  listing instead. No regression test for the fix itself unless a concrete problem turns up
  ([busy-ibis](../../playtests/2026-10-03-busy-ibis.md), statement 12: "no regression test needed
  for now -- unless we find some concrete issues").
