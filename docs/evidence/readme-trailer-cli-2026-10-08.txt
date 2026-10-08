README flag check: retained Linux CI failure excerpt

Date: 2026-10-08
PR: https://github.com/JosuaKrause/nappy/pull/629
Source: cdea6994a07e8c668c2166a4f7b4bf2169fb14c0
Run: https://github.com/JosuaKrause/nappy/actions/runs/37777505589
Job: gates / Check --help/-h and rejection on every shell tool
Command: ./tools/test_cli_help.sh

The following messages occur consecutively at 12:33:25 UTC. GitHub's repeated job and
timestamp prefixes are omitted; message text is unchanged.

./tools/test_cli_help.sh: line 549: printf: write error: Broken pipe
FAIL --walk is in dev_flags.gd's DEV_FLAG_TABLE but not in README.md's Dev flags section
./tools/test_cli_help.sh: line 549: printf: write error: Broken pipe
FAIL --flee is in dev_flags.gd's DEV_FLAG_TABLE but not in README.md's Dev flags section
./tools/test_cli_help.sh: line 549: printf: write error: Broken pipe
FAIL --press is in dev_flags.gd's DEV_FLAG_TABLE but not in README.md's Dev flags section

The complete failing job ends with:
331 checks, 3 failures

These flags exist in the checked source's README Dev flags section. The evidence establishes
a false negative from the printf/grep pipeline under pipefail; it does not claim that every
platform or every run of that pipeline fails. The production game is not executed by this
stubbed command-line contract suite.
