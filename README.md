# pqminer Hive loader 2

The existing installation URL stays unchanged:

`https://raw.githubusercontent.com/dren3451/pqminer-hive/main/pqminer-loader1.tar.gz`

The archive now contains loader **2**. The filename remains `loader1` for existing
Hive flight sheets. It contains Hive scripts, read-only diagnostics and license
texts; no mining binary, recovered CUDA module or credential is published here.
The miner is downloaded from the private `dren3451/pqminer` release with archive
and ELF checksum verification. A previous binary is kept as `pqminer.previous`.

## Flight sheet for the prepared CMP90 rig

| Field | Value |
|---|---|
| Miner name | `pqminer` |
| Installation URL | `https://raw.githubusercontent.com/dren3451/pqminer-hive/main/pqminer-loader1.tar.gz` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | Keep the selected Pearl pool |
| Pass | `x`, or the pool's existing setting |
| Extra config arguments | `-a pearl --pqminer-version 0.1.20 --pearl-kernel compact --pearl-base constant64 --pearl-k 65536` |

An existing `--gh-token` option is supported and stripped from miner arguments.
Without it, the loader reads the existing `/hive-config/pqminer.token` or
`/root/.config/pqminer/codex.token`. Token values are never part of this archive.
An explicit newer version can upgrade an older manual version floor; an older
flight cannot silently downgrade that floor. Existing pins are backed up when
advanced after a successful update.

Compact needs the checksum-pinned local module recovery data already present on
this CMP90 rig. It is not a self-contained compact installation for a fresh rig.
Other profiles and algorithms can keep their explicit settings.

## Diagnostics

After applying the flight and seeing work, run:

```bash
python3 /hive/miners/custom/pqminer/diagnose-cmp90.py
```

It samples three minutes of the local API, accepted/rejected counters, each GPU's
kernel and speed, GPU memory/processes and startup/verification status. It does
not stop/restart the miner, change files, or dump wallet/config/token contents.
The result is printed in the terminal and is not uploaded automatically.

Source files are included here. `bash build-loader.sh` rebuilds the stable URL's
archive and SHA256SUMS. `LOADER_VERSION` tracks the loader independently of the
private miner version.
