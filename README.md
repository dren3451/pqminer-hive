# pqminer Hive loader 3

Use the same installation URL:

`https://raw.githubusercontent.com/dren3451/pqminer-hive/main/pqminer-loader1.tar.gz`

The loader downloads the selected private normal release with archive and ELF
checksum verification, and retains the previous binary as `pqminer.previous`.

## Stable miner 0.1.22

The compact CUDA image is embedded directly in the miner. Its instruction stream
is preserved; only ELF name aliases change, and provenance/notices are retained.
The installed miner needs no separate module file or runtime module decoder.

Four CMP90 cards measured **334.5 TH/s** over 180 seconds, about **83.6 TH/s/card**,
matching the control. This preserves speed; 89 TH/s/card is not demonstrated.
CPU/GPU target sets, guarded buffers and CPU/Merkle proof checks pass.
Live-pool acceptance of the packaged version has not yet been observed.

| Flight-sheet field | Value |
| --- | --- |
| Miner name | `pqminer` |
| Installation URL | `https://raw.githubusercontent.com/dren3451/pqminer-hive/main/pqminer-loader1.tar.gz` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | Keep the selected Pearl pool |
| Pass | Keep the pool's existing setting |
| Extra config | `-a pearl --pqminer-version 0.1.22` |

The tested CMP90-only rig profile is selected automatically:
compact/constant64/K65536. Explicit kernel/base/K overrides retain precedence.
Keep the existing `--gh-token` option or protected token file. Token values do
not belong in chat or this repository. Pool, wallet and worker stay in the
flight sheet.

[Release 0.1.22](https://github.com/dren3451/pqminer/releases/tag/v0.1.22).

## Diagnostics

After applying the flight sheet and seeing work:

```bash
python3 /hive/miners/custom/pqminer/diagnose-cmp90.py
```

The read-only diagnostic checks the exact 0.1.22 binary and embedded module,
then samples three minutes of local API/GPU statistics and startup verification.
It does not restart mining or print wallet, configuration or token contents.
The terminal summary reports pool connectivity and accepted/rejected changes.

`bash build-loader.sh` reproducibly rebuilds the loader archive and SHA256SUMS.
`LOADER_VERSION` tracks the loader separately from the private miner version.
