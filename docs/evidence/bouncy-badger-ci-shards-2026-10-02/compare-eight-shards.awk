BEGIN {
    OFS = "\t"
}

FILENAME == ARGV[1] {
    if ($1 ~ /^test_.*\.gd$/) {
        cost[$1] = $2
    }
    next
}

FILENAME == ARGV[2] && /^shard / {
    shard = $2
    old_total[shard] = 0
    for (i = 4; i <= NF; i++) {
        old_shard[$i] = shard
        old_total[shard] += cost[$i]
        old_count[shard]++
    }
    next
}

FILENAME == ARGV[3] && /^shard / {
    shard = $2
    new_total[shard] = 0
    for (i = 4; i <= NF; i++) {
        new_shard[$i] = shard
        new_total[shard] += cost[$i]
        new_count[shard]++
    }
    next
}

END {
    print "assignment", "shard", "suite_count", "milliseconds"
    for (shard = 0; shard < 8; shard++) {
        print "old-reweighted", shard, old_count[shard], old_total[shard]
    }
    for (shard = 0; shard < 8; shard++) {
        print "refreshed", shard, new_count[shard], new_total[shard]
    }
    print ""
    print "suite", "milliseconds", "old_shard", "new_shard"
    for (suite in cost) {
        if (cost[suite] >= 50000 && old_shard[suite] != new_shard[suite]) {
            print suite, cost[suite], old_shard[suite], new_shard[suite]
        }
    }
}
