#!/usr/bin/env bash
cd "$(dirname "$0")"
. h-manifest.conf
mkdir -p "$(dirname "$CUSTOM_LOG_BASENAME")"
[[ ! -f $CUSTOM_CONFIG_FILENAME ]] && echo "no $CUSTOM_CONFIG_FILENAME, run h-config.sh" && exit 1
eval "args=($(< "$CUSTOM_CONFIG_FILENAME"))"
export PQ_COLOR=1
exec ./pqminer "${args[@]}" --api-port "$MINER_API_PORT" --log-file "${CUSTOM_LOG_BASENAME}.log" 2>&1
