#!/usr/bin/env bash
set -euo pipefail
umask 022
cd "$(dirname "$0")"
N=$(cat LOADER_VERSION)
[[ $N =~ ^[0-9]+$ ]]
STAGE=build/loader/pqminer
rm -rf build/loader
mkdir -p "$STAGE/third_party/nlohmann"
cp hive/h-config.sh hive/h-run.sh hive/h-stats.sh NOTICE "$STAGE/"
cp diagnose-cmp90.py "$STAGE/"
cp third_party/LICENSE.quantus-miner.Apache-2.0 "$STAGE/third_party/"
cp third_party/nlohmann/LICENSE.MIT "$STAGE/third_party/nlohmann/"
sed "s/__VERSION__/loader$N/" hive/h-manifest.conf > "$STAGE/h-manifest.conf"
chmod 755 "$STAGE"/*.sh
chmod 644 "$STAGE/diagnose-cmp90.py" "$STAGE/NOTICE" "$STAGE/h-manifest.conf" "$STAGE/third_party/"*.* "$STAGE/third_party/nlohmann/"*
tar -C build/loader --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner -czf pqminer-loader1.tar.gz pqminer
sha256sum pqminer-loader1.tar.gz diagnose-cmp90.py > SHA256SUMS
