#!/usr/bin/env bash
# Sourced by the HiveOS agent: must set $khs and $stats.
# pqminer serves both ready-made in its API (.hive.khs / .hive.stats).
. /hive/miners/custom/pqminer/h-manifest.conf
stats_raw=$(curl --connect-timeout 2 --max-time 5 --silent --noproxy '*' "http://127.0.0.1:${MINER_API_PORT}/")
if [[ $? -ne 0 || -z $stats_raw ]]; then
    echo -e "${YELLOW}pqminer API not responding on port ${MINER_API_PORT}${NOCOLOR}"
    khs=0
    stats=""
else
    khs=$(jq -r '.hive.khs // 0' <<< "$stats_raw")
    stats=$(jq -c '.hive.stats' <<< "$stats_raw")
fi
[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"
