#!/usr/bin/env bash
# tools/lint.sh — the volatile-fact linter.
#
# CLAUDE.md: "every document states what is true now and only what is true now" — no commit
# hash, no branch name, no check count, no ticked box, no status word in a heading. Those are
# exactly the sentence shapes that go stale the moment somebody merges, because nothing
# rereads a doc after the fact that made it true has passed. This scans for those shapes and
# fails loudly instead of waiting for the next reader to notice a lie.
#
#   tools/lint.sh              # the whole governed set
#   tools/lint.sh a.md b.md    # just these files (how the PostToolUse hook calls it)
#
# Governed: AGENTS.md, CLAUDE.md, .claude/skills/*/SKILL.md, README.md and docs/*.md — except
# docs/DECISIONS.md and docs/PLAYTEST-*.md, which are history and primary sources and are
# allowed to say what was true then, and docs/evidence/README.md, whose job is filenames that
# embed hashes.
#
# A hit is `file:line: label`, and a nonzero exit if there is at least one. The marker
# `lint-allow` inside an HTML comment on the same line is a deliberate exception and is not
# reported.
#
# Bash 3.2-safe (no associative arrays, no globstar), no dependency beyond grep/sed/awk.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1

files=()
if [[ $# -gt 0 ]]; then
    files=("$@")
else
    [[ -f AGENTS.md ]] && files+=("AGENTS.md")
    [[ -f CLAUDE.md ]] && files+=("CLAUDE.md")
    [[ -f README.md ]] && files+=("README.md")
    for f in .claude/skills/*/SKILL.md; do
        [[ -f "$f" ]] && files+=("$f")
    done
    for f in docs/*.md; do
        [[ -f "$f" ]] && files+=("$f")
    done
fi

hits=0

# True if the line carries a same-line `lint-allow` HTML-comment escape.
is_allowed() {
    printf '%s\n' "$1" | grep -qE '<!--[^>]*lint-allow[^>]*-->'
}

# $1 file  $2 line number  $3 label  $4 full line text (checked for the escape hatch)
report() {
    if is_allowed "$4"; then
        return
    fi
    printf '%s:%s: %s\n' "$1" "$2" "$3"
    hits=$((hits + 1))
}

# A backticked 7-40 digit hex string: shaped exactly like a git commit hash.
lint_hex() {
    local f="$1" n content
    while IFS=: read -r n content; do
        report "$f" "$n" "backticked commit-hash-shaped hex string" "$content"
    done < <(grep -nE '`[0-9a-f]{7,40}`' "$f")
}

# A branch name: feature/<slug>.
lint_branch() {
    local f="$1" n content
    while IFS=: read -r n content; do
        report "$f" "$n" "branch name" "$content"
    done < <(grep -nE '(^|[^a-zA-Z0-9_])feature/[a-z0-9-]+' "$f")
}

# A check count: "NN checks" or "checks, NN failures".
lint_checks() {
    local f="$1" n content
    while IFS=: read -r n content; do
        report "$f" "$n" "check count" "$content"
    done < <(grep -nE '[0-9]+ checks|checks, [0-9]+ failures' "$f")
}

# A ticked box: "- [x]", at the start of a (possibly indented) list item.
lint_ticked() {
    local f="$1" n content
    while IFS=: read -r n content; do
        report "$f" "$n" "ticked box" "$content"
    done < <(grep -nE '^[[:space:]]*- \[x\]' "$f")
}

# A status word after a "·" in a heading line (# through ####).
lint_heading_status() {
    local f="$1" n content after
    while IFS=: read -r n content; do
        after="${content#*·}"
        [[ "$after" == "$content" ]] && continue
        if printf '%s\n' "$after" | grep -qE '(^|[^a-zA-Z])(in progress|not started|partly built|done)([^a-zA-Z]|$)'; then
            report "$f" "$n" "status word in a heading" "$content"
        fi
    done < <(grep -nE '^#{1,4} .*·' "$f")
}

for f in "${files[@]}"; do
    case "$f" in
        docs/DECISIONS.md|docs/PLAYTEST-*.md|docs/evidence/README.md)
            continue
            ;;
    esac
    [[ -f "$f" ]] || continue
    lint_hex "$f"
    lint_branch "$f"
    lint_checks "$f"
    lint_ticked "$f"
    lint_heading_status "$f"
done

if [[ "$hits" -gt 0 ]]; then
    echo
    echo "FAILED: $hits volatile-fact hit(s)" >&2
    exit 1
fi

echo "OK"
