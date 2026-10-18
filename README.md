# pqminer-hive

HiveOS loader for **pqminer** (Pearl + Quantus CUDA miner, 0% dev fee).

This repository holds only the HiveOS custom-miner scripts (no miner code, no binary, no
tokens). On every miner start the loader downloads/updates the pqminer binary from its
private release using the GitHub token given in the flight sheet.

## Flight sheet (Custom miner)

| Field | Value |
|---|---|
| Miner name | `pqminer` |
| Installation URL | `https://raw.githubusercontent.com/dren3451/pqminer-hive/main/pqminer-loader1.tar.gz` |
| Hash algorithm | — |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | your pool, e.g. HeroMiners Pearl port 1200 (no SSL) |
| Pass | `x` |
| Extra config arguments | `-a pearl --gh-token github_pat_...` |

Optional: `--pqminer-version 0.1.0` pins a version (default: latest release).
