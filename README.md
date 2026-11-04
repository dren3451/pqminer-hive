# pqminer Hive loader 2

The installation URL remains:

`https://raw.githubusercontent.com/dren3451/pqminer-hive/main/pqminer-loader1.tar.gz`

The archive contains Hive scripts, read-only diagnostics and license texts.
It downloads the selected private pqminer release with archive and ELF checksum
verification and retains a previous binary as `pqminer.previous`.

## Standalone compact preview 0.1.21

Version 0.1.21 implements compact in project CUDA C++ and inline PTX, compiled
into the normal miner binary. It requires no external kernel data file or
runtime decoder for compact mode.

This is a **development prerelease**, not a speed upgrade. A 180-second
four-CMP90 synthetic test measured **283.4 TH/s total**, about **70.85 per GPU**.
That is below the currently installed profile's approximately 83.5 per GPU.
The 89 TH/s goal has not been reached. Live-pool acceptance for this new
implementation is still unverified. The prerelease does not replace the stable
latest release or change an existing flight sheet automatically.

| Field | Value |
|---|---|
| Miner name | `pqminer` |
| Installation URL | `https://raw.githubusercontent.com/dren3451/pqminer-hive/main/pqminer-loader1.tar.gz` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | Keep the selected Pearl pool |
| Pass | `x`, or the pool's existing setting |
| Preview extra config | `-a pearl --pqminer-version 0.1.21 --pearl-kernel compact --pearl-base constant64 --pearl-k 65536` |

[Preview release](https://github.com/dren3451/pqminer/releases/tag/v0.1.21).
Existing users can retain their current version pin. Keep the existing
`--gh-token` option when present; its value must never be posted in chat or
committed to this repository. The loader can also use existing token files.
Pool, wallet and worker settings remain in the flight sheet.

## Diagnostics

After applying a flight sheet and seeing work, run:

```bash
python3 /hive/miners/custom/pqminer/diagnose-cmp90.py
```

It samples three minutes of local API counters, per-GPU kernel/rate,
GPU memory/processes and startup/verification status. It does not restart
mining or print wallet/config/token contents. Output stays in the terminal.

`bash build-loader.sh` rebuilds the archive and SHA256SUMS. `LOADER_VERSION`
tracks the loader separately from the private miner version.
