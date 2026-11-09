#!/usr/bin/env bash
# Sourced by tools/prune-merged.sh and tools/agent-setup.sh: which ignored files a worktree may
# still hold when it is removed.
#
# A non-forced `git worktree remove` deletes ignored files without a word and `git status` never
# lists them, so a tool that removes a worktree sorts them first: the ones the repository or the OS
# regenerates may go, and anything else ignored (a recording or a capture under `build/`, a `.env`
# holding a token) keeps the worktree.
#
# Bash 3.2-safe, like the rest of tools/.

# The ignored paths a worktree may still hold and be removed, because the repository or the OS
# regenerates them: Godot's import cache, the Python environment and its caches, Finder metadata,
# the baked atlas pages (tools/bake-atlases.sh), the Web-template compiler scratch, and the
# `.gdignore` that export-web.sh and build-web-template.sh drop into `build/`. An entry with a `/`
# inside it is anchored at the worktree's root; one without matches at any depth.
REGENERABLE_IGNORED=".godot/ .venv/ __pycache__/ .mypy_cache/ .ruff_cache/ .DS_Store
  assets/atlases/baked/ build/web-template-work/ build/.gdignore"

# Sort the ignored files in worktree $1 into regenerable cache roots ("cache<TAB>root") and
# anything else ("keep<TAB>path"); $2 is further entries to allow, in REGENERABLE_IGNORED's own
# form ("" for none).
classify_ignored() {
    git --no-optional-locks -C "$1" -c core.quotePath=false ls-files --others --ignored \
        --exclude-standard \
        | PRUNE_ALLOWED="$REGENERABLE_IGNORED $2" awk '
            BEGIN { n = split(ENVIRON["PRUNE_ALLOWED"], allow) }
            {
                p = $0; root = ""
                for (i = 1; i <= n && root == ""; i++) {
                    e = allow[i]; dir = substr(e, length(e)) == "/"
                    bare = dir ? substr(e, 1, length(e) - 1) : e
                    if (index(bare, "/")) {
                        if (dir ? index(p, e) == 1 : p == e) root = e
                    } else if (dir) {
                        if (index(p, e) == 1) root = e
                        else if ((k = index(p, "/" e)) > 0) root = substr(p, 1, k + length(e))
                    } else if (p == e || substr(p, length(p) - length(e)) == "/" e) {
                        root = p
                    }
                }
                if (root == "") print "keep\t" p
                else if (!(root in seen)) { seen[root] = 1; print "cache\t" root }
            }'
}
