#!/usr/bin/env bash
# Cuts the next release: reads the latest version tag, bumps it by the given part, and pushes the
# new tag -- which is what `.github/workflows/deploy.yml` now triggers on, so pushing the tag *is*
# publishing the site. The point is in the instruction that asked for this: "that way we don't
# have to reason about what the next version is."
#
#   tools/release.sh major          # v1.2.3 -> v2.0.0, prints the plan and stops
#   tools/release.sh minor          # v1.2.3 -> v1.3.0, prints the plan and stops
#   tools/release.sh patch          # v1.2.3 -> v1.2.4, prints the plan and stops
#   tools/release.sh patch push     # actually tags and pushes, once every refusal below passes
#
# Semver, with `major` reserved for a change that breaks or fundamentally alters the game -- the
# argument nobody reaches for casually.
#
# **Read loosely, write strictly.** The latest tag may be a bare `v123` (understood as `v123.0.0`)
# or `v123.45.6`; what this script writes is always `vMAJOR.MINOR.PATCH`, so the shape converges
# after one release. With no version tag at all it starts from `v0.0.0`.
#
# **Confirmation is a second argument, not a prompt.** `tools/telemetry.sh -p` already uses this
# shape -- print what would happen, and only act when told `yes` (there, `push` here) -- because a
# script that blocks on a TTY read is a script nobody can drive from a rig or a note in a session.
# Pushing a tag here is publishing a build, so this still owes what an irreversible command owes:
# it refuses a dirty tree, refuses anywhere but `main`, and refuses when `main` is not level with
# `origin/main` -- a tag on a commit the remote has never seen deploys something nobody can check
# out -- and every refusal fires whether or not `push` was given, so the dry run tells the truth
# about whether the real thing would work.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

PART="${1:-}"
case "$PART" in
    major|minor|patch) ;;
    *)
        echo "usage: tools/release.sh <major|minor|patch> [push]" >&2
        exit 1
        ;;
esac
CONFIRMED=0
[[ "${2:-}" == "push" ]] && CONFIRMED=1

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "main" ]]; then
    echo "refusing: on branch '$BRANCH', not main" >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "refusing: the working tree is not clean" >&2
    git status --porcelain >&2
    exit 1
fi

git fetch origin main --quiet
LOCAL="$(git rev-parse main)"
REMOTE="$(git rev-parse origin/main)"
if [[ "$LOCAL" != "$REMOTE" ]]; then
    echo "refusing: main ($LOCAL) is not level with origin/main ($REMOTE)" >&2
    echo "a tag on a commit the remote has never seen deploys something nobody can check out" >&2
    exit 1
fi

# The latest version tag, ordered with `sort -V` rather than a plain lexical sort, which would put
# v1.10.0 before v1.9.0. Read loosely: a tag with fewer than three dot-separated parts is padded
# with zeros below.
LATEST="$(git tag -l 'v[0-9]*' | sort -V | tail -n1)"
if [[ -z "$LATEST" ]]; then
    CUR_MAJOR=0; CUR_MINOR=0; CUR_PATCH=0
else
    BODY="${LATEST#v}"
    IFS='.' read -r CUR_MAJOR CUR_MINOR CUR_PATCH <<<"$BODY"
    CUR_MAJOR="${CUR_MAJOR:-0}"
    CUR_MINOR="${CUR_MINOR:-0}"
    CUR_PATCH="${CUR_PATCH:-0}"
fi
CURRENT="v${CUR_MAJOR}.${CUR_MINOR}.${CUR_PATCH}"

case "$PART" in
    major) NEXT="v$((CUR_MAJOR + 1)).0.0" ;;
    minor) NEXT="v${CUR_MAJOR}.$((CUR_MINOR + 1)).0" ;;
    patch) NEXT="v${CUR_MAJOR}.${CUR_MINOR}.$((CUR_PATCH + 1))" ;;
esac

echo "current: $CURRENT"
echo "next:    $NEXT  ($PART)"

if [[ $CONFIRMED -ne 1 ]]; then
    echo "" >&2
    echo "dry run -- nothing tagged or pushed. Run 'tools/release.sh $PART push' to publish $NEXT." >&2
    exit 0
fi

git tag -a "$NEXT" -m "$NEXT"
git push origin "$NEXT"
echo "pushed $NEXT -- deploy.yml will build and publish it"
