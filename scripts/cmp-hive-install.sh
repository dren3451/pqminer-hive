#!/usr/bin/env bash
# CMP HiveOS persistent unlock installer (50HX or 90HX, pure rigs only).
# Upstream: pearlfortune/cmpunlocker v0.1.28; does not flash VBIOS.
# Usage: bash cmp-hive-install.sh check|install|verify
set -Eeuo pipefail

MODE="${1:-check}"
case "$MODE" in check|install|verify) ;; *) echo "Usage: $0 check|install|verify" >&2; exit 2;; esac
err(){ echo "ERROR: $*" >&2; exit 1; }
info(){ echo "==> $*"; }
command -v lspci >/dev/null || err "Missing pciutils/lspci"
command -v modinfo >/dev/null || err "Missing modinfo"
[ "$(id -u)" -eq 0 ] || err "Run as root"
K="$(uname -r)"
D="$(modinfo -F version nvidia 2>/dev/null || true)"
MOD="$(modinfo -n nvidia 2>/dev/null || true)"
LICENSE="$(modinfo -F license nvidia 2>/dev/null || true)"
mapfile -t GPUS < <(lspci -Dnn | grep -iE 'NVIDIA.*\[10de:(1e09|220d)\]' | awk '{print $1}' || true)
[ "${#GPUS[@]}" -gt 0 ] || err "No CMP 50HX/90HX PCI IDs found"
A50=0; A90=0
for bdf in "${GPUS[@]}"; do
  id="$(cat "/sys/bus/pci/devices/$bdf/device")"
  case "$id" in 0x1e09) A50=$((A50+1));; 0x220d) A90=$((A90+1));; esac
done
info "Cards: CMP50HX=$A50 CMP90HX=$A90 ; kernel=$K ; driver=$D ; module=$MOD"
[ "$A50" -eq 0 ] || [ "$A90" -eq 0 ] || err "Mixed CMP50/CMP90: separate patched drivers can conflict. Not automated."
CARD=50
[ "$A90" -eq 0 ] || CARD=90
case "$CARD:$D:$K" in
  50:580.173.02:6.1.0-hiveos|50:610.43.03:6.1.0-hiveos|50:610.43.03:6.10.0-hiveos|90:610.43.03:6.10.0-hiveos) ;;
  *) err "Unsupported persistent combo: CMP${CARD}HX / $D / $K. Do not update the driver automatically.";;
esac
case "$LICENSE" in *MIT*|*GPL*) ;; *) err "Driver is not confirmed NVIDIA Open ($LICENSE)";; esac
if [ "$CARD" = 90 ]; then
  for bdf in "${GPUS[@]}"; do
    subvendor="$(cat "/sys/bus/pci/devices/$bdf/subsystem_vendor")"
    subdevice="$(cat "/sys/bus/pci/devices/$bdf/subsystem_device")"
    [ "$subvendor:$subdevice" = '0x10de:0x1555' ] || err "Unsupported CMP90 subsystem on $bdf: $subvendor:$subdevice"
  done
  command -v nvidia-smi >/dev/null || err "nvidia-smi missing, cannot check CMP90 VBIOS"
  mapfile -t VBIOS < <(nvidia-smi --query-gpu=vbios_version --format=csv,noheader,nounits | tr -d '\r ')
  [ "${#VBIOS[@]}" -eq "${#GPUS[@]}" ] || err "nvidia-smi GPU count does not match CMP90 count"
  for vb in "${VBIOS[@]}"; do
    [ "$vb" = '94.02.74.00.01' ] || err "Unsupported CMP90 VBIOS $vb (persistent preview only validates .01)"
  done
else
  for bdf in "${GPUS[@]}"; do
    sv="$(cat "/sys/bus/pci/devices/$bdf/subsystem_vendor")"
    sd="$(cat "/sys/bus/pci/devices/$bdf/subsystem_device")"
    case "$sv:$sd" in 0x10de:0x1554|0x1462:0x371f) ;; *) err "Unsupported CMP50 subsystem on $bdf: $sv:$sd";; esac
  done
fi
[ "$MODE" != install ] || {
  [ -d "/lib/modules/$K/build" ] || err "Kernel headers missing: /lib/modules/$K/build"
  for cmd in make gcc patch ar ld strings curl tar sha256sum; do command -v "$cmd" >/dev/null || err "Missing $cmd"; done
  if [ -d /sys/firmware/efi ] && command -v mokutil >/dev/null; then
    if mokutil --sb-state 2>/dev/null | grep -qi 'enabled'; then err 'Secure Boot enabled: unsupported for patched module'; fi
  fi
  case "$MOD" in *forge-cmp*|*cmpunlocker*|*cmp50hx*|*cmp90hx*) err "Already modified NVIDIA module detected: $MOD. Won't overwrite.";; esac
  if pgrep -af 'srbminer|pqminer|rgminer|lolMiner|T-Rex|nbminer|onezerominer|wildrig' | grep -v -E 'cmp-hive-install|pgrep -af|grep -v' ; then
    err 'Miner running. Stop it in HiveOS before installing on a new rig.'
  fi
}

BASE='/opt/cmp-hive-unlock/v0.1.28'
ASSET="cmpunlocker-v0.1.28-linux-x64-${CARD}hx-stockflow"
ROOT="$BASE/$ASSET"
BIN="$ROOT/cmpunlocker-rs"

if [ "$MODE" = check ]; then
  info "Preflight OK for persistent CMP${CARD}HX installation, no changes made."
  info "Run: bash $0 install ; reboot manually after successful install."
  exit 0
fi
if [ "$MODE" = verify ]; then
  [ -x "$BIN" ] || err "Unlocker not installed at $BIN"
  info "Loaded driver path: $(modinfo -n nvidia)"
  if [ "$CARD" = 50 ]; then "$BIN" compute50hx-v534 verify --all-cmp50hx --expect full
  else "$BIN" compute90hx-v67 verify --all-cmp90hx --expect full; fi
  exit 0
fi

mkdir -p "$BASE"; cd "$BASE"
RELEASE='https://github.com/pearlfortune/cmpunlocker/releases/download/v0.1.28'
info "Fetching upstream v0.1.28 and checking checksum"
curl -fL --retry 3 -o SHA256SUMS "$RELEASE/SHA256SUMS"
curl -fL --retry 3 -o "$ASSET.tar.gz" "$RELEASE/$ASSET.tar.gz"
grep -F "$ASSET.tar.gz" SHA256SUMS > "SHA256SUMS.$CARD" || err 'Asset not listed in SHA256SUMS'
sha256sum --check "SHA256SUMS.$CARD" || err 'SHA256 mismatch'
# Avoid using tar as root against unexpected absolute/parent paths.
tar tf "$ASSET.tar.gz" > "$ASSET.paths"
if grep -Eq '(^/|(^|/)\.\.(/|$))' "$ASSET.paths"; then err 'Unsafe archive paths'; fi
tar xzf "$ASSET.tar.gz"
[ -x "$BIN" ] || err "Missing binary $BIN"
info "Unlocker: $($BIN --version)"
SRC="NVIDIA-kernel-module-source-$D.tar.xz"
SRC_URL="https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/$SRC"
WORK="$ROOT/stockflow/$D"
[ -x "$WORK/build-candidate.sh" ] || err "Expected build tool missing at $WORK"
curl -fL --retry 3 -o "$ROOT/$SRC" "$SRC_URL"
info "Building patched driver for current kernel (JOBS=1)"
cd "$WORK"
if [ "$CARD" = 90 ]; then
  JOBS=1 CMP90_STOCKFLOW_VARIANT=rejoin15 CMP90_STOCKFLOW_LOW_MEM_G_BINDATA=1 \
    ./build-candidate.sh --source-tarball "$ROOT/$SRC"
  ART="$WORK/artifacts/$D-$K-rejoin15-serialized-start"
else
  JOBS=1 ./build-candidate.sh --source-tarball "$ROOT/$SRC"
  ART="$WORK/artifacts/$D-$K-v551-stockflow"
fi
[ -f "$ART/nvidia.ko" ] || err "Build incomplete: missing $ART/nvidia.ko"
[ "$(modinfo -F version "$ART/nvidia.ko")" = "$D" ] || err 'Built driver version mismatch'
modinfo -F vermagic "$ART/nvidia.ko" | grep -Fq "$K" || err 'Built kernel mismatch'
info "Installing persistent CMP${CARD}HX module. No automatic reboot."
if [ "$CARD" = 90 ]; then
  "$WORK/stockflow-install.sh" --artifact "$ART" \
    --acknowledge I-ACCEPT-90HX-STOCKFLOW-PERSISTENT-INSTALL
else
  cd "$ROOT"
  "$BIN" compute50hx-v534 stockflow-probe --all-cmp50hx \
    --stockflow-candidate "$ART" \
    --acknowledge I-ACCEPT-50HX-V534-COMPUTE-UNLOCK
  "$BIN" compute50hx-v534 stockflow-install \
    --stockflow-candidate "$ART" \
    --acknowledge I-ACCEPT-50HX-V534-COMPUTE-UNLOCK
fi
info 'INSTALL FINISHED. Reboot manually after saving any logs, then verify:'
info "bash $0 verify"
info "Backup or restore instructions: https://github.com/pearlfortune/cmpunlocker/blob/main/README.en.md"
