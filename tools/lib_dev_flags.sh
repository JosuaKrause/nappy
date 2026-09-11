# Shared by tools/run.sh and tools/shot.sh: the one place either script's accept-list for a
# dev flag it forwards to the game lives. Not a script of its own -- `source` it after PROJECT_DIR
# is set.
#
# The accept-list is read live out of src/dev/dev_flags.gd's own DEV_FLAG_TABLE comment block on
# every call, rather than copied here by hand, so a flag added to that table is accepted the next
# time either script runs and a typo is rejected the same way -- see the cli-tools skill and
# dev_flags.gd's own doc comment for what the table's columns mean.

# Prints "flag arity" pairs, one per line, extracted from dev_flags.gd's DEV_FLAG_TABLE.
_dev_flag_table() {
    local file="$PROJECT_DIR/src/dev/dev_flags.gd"
    sed -n '/^## DEV_FLAG_TABLE$/,/^## END_DEV_FLAG_TABLE$/p' "$file" \
        | sed -e '1d' -e '$d' -e 's/^##[[:space:]]*//' \
        | awk 'NF==2'
}

# Loud failure if the table cannot be found at all -- a renamed marker must not silently make
# every flag "unknown" (nothing would ever work) or silently accept everything (the whole point
# of validating). Call once, before trusting the table for anything.
_dev_flag_table_assert() {
    local count
    count="$(_dev_flag_table | wc -l | tr -d ' ')"
    if [[ "$count" -lt 1 ]]; then
        echo "internal error: no DEV_FLAG_TABLE found in src/dev/dev_flags.gd -- the manifest" >&2
        echo "the accept-list is read from is missing or its markers were renamed" >&2
        exit 70
    fi
}

# Prints every flag name in the table, one per line -- what a script's --help lists.
dev_flag_names() {
    _dev_flag_table | awk '{print $1}'
}

# Prints "--flag ARGS" for every row, ARGS spelled out from the arity code so a script's --help
# says what each flag takes without a second, hand-typed copy of the table to drift from it.
# Semantics (what the value *means*) stay in README.md's own table; this is shape only.
dev_flag_usage_lines() {
    local name arity args
    while read -r name arity; do
        local required="${arity%%[!0-9]*}"
        [[ -z "$required" ]] && required=0
        local suffix="${arity#"$required"}"
        args=""
        local k=0
        while (( k < required )); do args+=" <value>"; k=$(( k + 1 )); done
        case "$suffix" in
            *w\?*) args+=" [value]" ;;
            *\?*)  args+=" [number]" ;;
        esac
        case "$suffix" in
            *\**) args+=" (repeatable)" ;;
        esac
        printf '  %s%s\n' "$name" "$args"
    done < <(_dev_flag_table)
}

# The arity code for $1 (see dev_flags.gd's own doc comment), or a nonzero exit if $1 is not in
# the table at all.
_dev_flag_arity() {
    local flag="$1" name arity
    while read -r name arity; do
        if [[ "$name" == "$flag" ]]; then
            printf '%s\n' "$arity"
            return 0
        fi
    done < <(_dev_flag_table)
    return 1
}

# Validates a list of arguments meant to be forwarded to the game as dev flags: an unknown
# --flag, a flag missing its required value, or a bare word that is not a value some preceding
# flag consumed, each print one line on stderr and return non-zero -- before the caller ever
# spends a Godot launch on finding out the same way. Silent and returns 0 when every argument is
# accounted for.
validate_dev_flags() {
    _dev_flag_table_assert
    local -a args=("$@")
    local n=${#args[@]}
    local i=0
    while (( i < n )); do
        local tok="${args[$i]}"
        if [[ "$tok" != --* ]]; then
            echo "unrecognized argument (not a known flag, and not the value of the flag before it): $tok" >&2
            return 1
        fi
        local arity
        if ! arity="$(_dev_flag_arity "$tok")"; then
            echo "unknown dev flag: $tok" >&2
            return 1
        fi
        i=$(( i + 1 ))
        local required="${arity%%[!0-9]*}"
        [[ -z "$required" ]] && required=0
        local consumed=0
        while (( consumed < required )); do
            if (( i >= n )); then
                echo "$tok is missing its value" >&2
                return 1
            fi
            i=$(( i + 1 ))
            consumed=$(( consumed + 1 ))
        done
        local suffix="${arity#"$required"}"
        case "$suffix" in
            *w\?*)
                if (( i < n )) && [[ "${args[$i]}" != --* ]]; then
                    i=$(( i + 1 ))
                fi
                ;;
            *\?*)
                if (( i < n )) && [[ "${args[$i]}" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
                    i=$(( i + 1 ))
                fi
                ;;
        esac
    done
    return 0
}
