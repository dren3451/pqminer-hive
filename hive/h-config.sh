#!/usr/bin/env bash
# HiveOS: runs before every miner start. Builds pqminer.conf from the flight sheet
# and, when a GitHub token is given, installs/updates the pqminer binary from the
# private release (so the flight sheet can point at the small public loader package).
#
# Flight sheet (Custom miner):
#   Miner name:        pqminer
#   Wallet template:   %WAL%.%WORKER_NAME%
#   Pool URL:          stratum+tcp://<pool>:<port>   (several = failover)
#   Extra config:      -a pearl --gh-token github_pat_...   [--pqminer-version 0.1.0]
[[ -z $CUSTOM_CONFIG_FILENAME ]] && . /hive/miners/custom/pqminer/h-manifest.conf

PQ_DIR=${PQ_DIR:-/hive/miners/custom/pqminer}
PQ_REPO=dren3451/pqminer

pq_version_gt() {
    local -a left right
    local i
    [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && $2 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
    IFS=. read -r -a left <<< "$1"
    IFS=. read -r -a right <<< "$2"
    for i in 0 1 2; do
        ((10#${left[$i]} > 10#${right[$i]})) && return 0
        ((10#${left[$i]} < 10#${right[$i]})) && return 1
    done
    return 1
}

pq_update_local_pin() {
    [[ -f $PQ_DIR/.validated-version ]] || return 0
    local previous
    previous=$(< "$PQ_DIR/.validated-version")
    if pq_version_gt "$1" "$previous"; then
        cp -p "$PQ_DIR/.validated-version" "$PQ_DIR/.validated-version.previous-loader"
        printf '%s\n' "$1" > "$PQ_DIR/.validated-version.new"
        mv -f "$PQ_DIR/.validated-version.new" "$PQ_DIR/.validated-version"
    fi
}

# Installs/updates the binary from the private release. Uses gh_token and pin
# from pq_config_main (dynamic scope).
pq_fetch() {
    local api="https://api.github.com/repos/$PQ_REPO/releases/latest"
    [[ -n $pin ]] && api="https://api.github.com/repos/$PQ_REPO/releases/tags/v${pin#v}"
    local rel name id ver tmp f sums_id expected actual
    rel=$(curl -fsSL --connect-timeout 10 --max-time 30 -H "Authorization: Bearer $gh_token" \
        -H "Accept: application/vnd.github+json" "$api") || return 1
    name=$(jq -r '[.assets[] | select(.name | test("^pqminer-[^-]+\\.tar\\.gz$"))][0].name // empty' <<< "$rel")
    id=$(jq -r '[.assets[] | select(.name | test("^pqminer-[^-]+\\.tar\\.gz$"))][0].id // empty' <<< "$rel")
    [[ -z $id ]] && return 1
    ver=${name#pqminer-}
    ver=${ver%.tar.gz}
    [[ $ver =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
    if [[ -x $PQ_DIR/pqminer && "$(cat "$PQ_DIR/.binver" 2>/dev/null)" == "$ver" ]]; then
        pq_update_local_pin "$ver" || return 1
        return 0
    fi
    echo "pqminer: installing $ver"
    tmp=$(mktemp -d)
    # curl does not forward the Authorization header to the storage host on redirect
    sums_id=$(jq -r '[.assets[] | select(.name == "SHA256SUMS")][0].id // empty' <<< "$rel")
    [[ -n $sums_id ]] || { echo 'pqminer: release checksum file missing' >&2; rm -rf "$tmp"; return 1; }
    if ! curl -fsSL --connect-timeout 10 --max-time 300 -H "Authorization: Bearer $gh_token" \
        -H "Accept: application/octet-stream" -o "$tmp/p.tgz" \
        "https://api.github.com/repos/$PQ_REPO/releases/assets/$id" ||
        ! curl -fsSL --connect-timeout 10 --max-time 60 -H "Authorization: Bearer $gh_token" \
        -H "Accept: application/octet-stream" -o "$tmp/SHA256SUMS" \
        "https://api.github.com/repos/$PQ_REPO/releases/assets/$sums_id"; then
        rm -rf "$tmp"
        return 1
    fi
    expected=$(awk -v n="$name" '$2 == n || $2 == "build/" n {print $1; exit}' "$tmp/SHA256SUMS")
    actual=$(sha256sum "$tmp/p.tgz"); actual=${actual%% *}
    if [[ ! $expected =~ ^[0-9a-f]{64}$ || $actual != "$expected" ]]; then
        echo 'pqminer: archive checksum mismatch' >&2
        rm -rf "$tmp"; return 1
    fi
    if ! tar -xzf "$tmp/p.tgz" -C "$tmp" || [[ ! -f $tmp/pqminer/pqminer ]]; then
        rm -rf "$tmp"; return 1
    fi
    expected=$(awk '$2 == "pqminer" || $2 == "build/pqminer" {print $1; exit}' "$tmp/SHA256SUMS")
    actual=$(sha256sum "$tmp/pqminer/pqminer"); actual=${actual%% *}
    if [[ ! $expected =~ ^[0-9a-f]{64}$ || $actual != "$expected" ]]; then
        echo 'pqminer: binary checksum mismatch' >&2
        rm -rf "$tmp"; return 1
    fi
    if [[ -x $PQ_DIR/pqminer ]]; then
        cp -p "$PQ_DIR/pqminer" "$PQ_DIR/pqminer.previous" || { rm -rf "$tmp"; return 1; }
        [[ ! -f $PQ_DIR/.binver ]] || cp -p "$PQ_DIR/.binver" "$PQ_DIR/.binver.previous"
    fi
    if ! install -m 755 "$tmp/pqminer/pqminer" "$PQ_DIR/pqminer.new" || ! mv -f "$PQ_DIR/pqminer.new" "$PQ_DIR/pqminer"; then
        rm -rf "$tmp"; return 1
    fi
    # scripts that are not running right now may be refreshed too
    for f in h-run.sh h-stats.sh NOTICE install.sh; do
        [[ -f $tmp/pqminer/$f ]] && cp -f "$tmp/pqminer/$f" "$PQ_DIR/$f"
    done
    mkdir -p "$PQ_DIR/third_party/nlohmann"
    for f in third_party/LICENSE.quantus-miner.Apache-2.0 third_party/nlohmann/LICENSE.MIT; do
        [[ -f $tmp/pqminer/$f ]] && cp -f "$tmp/pqminer/$f" "$PQ_DIR/$f"
    done
    chmod +x "$PQ_DIR"/*.sh 2>/dev/null
    echo "$ver" > "$PQ_DIR/.binver"
    pq_update_local_pin "$ver" || { rm -rf "$tmp"; return 1; }
    rm -rf "$tmp"
    echo "pqminer: $ver installed"
}

# All state is local: HiveOS sources this file into its own shell.
pq_config_main() {
    # ---- options for the loader itself (stripped before they reach pqminer) -----------
    local gh_token="" pin="" w i=0 user_args algo url a token_file validated
    local -a rest=() words=() conf=()
    read -r -a words <<< "$CUSTOM_USER_CONFIG"
    while ((i < ${#words[@]})); do
        w=${words[$i]}
        case $w in
            --gh-token)          gh_token=${words[$((i + 1))]}; i=$((i + 2)); continue ;;
            --gh-token=*)        gh_token=${w#*=} ;;
            --pqminer-version)   pin=${words[$((i + 1))]}; i=$((i + 2)); continue ;;
            --pqminer-version=*) pin=${w#*=} ;;
            *)                   rest+=("$w") ;;
        esac
        i=$((i + 1))
    done
    user_args="${rest[*]}"
    for token_file in /hive-config/pqminer.token "${PQ_TOKEN_FILE:-/root/.config/pqminer/codex.token}"; do
        [[ -z $gh_token && -r $token_file ]] && gh_token=$(< "$token_file")
    done
    # A checksum-validated manual install is pinned until its local pin is
    # removed. Ordinary loader installs keep the dashboard/latest behavior.
    if [[ -f $PQ_DIR/.validated-version ]]; then
        validated=$(< "$PQ_DIR/.validated-version")
        [[ $validated =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'pqminer: invalid local version pin' >&2; return 1; }
        # Preserve the manual floor, while allowing an explicit newer flight.
        pq_version_gt "${pin#v}" "$validated" || pin=$validated
    fi
    [[ -z $pin || ${pin#v} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'pqminer: invalid flight-sheet version' >&2; return 1; }

    # ---- install / update the binary from the private release ------------------------

    if [[ -n $gh_token ]]; then
        if ! pq_fetch; then
            if [[ -x $PQ_DIR/pqminer ]]; then
                echo "pqminer: update check failed (network or token), starting the installed version"
            else
                echo "pqminer: cannot download the miner: check --gh-token in the flight sheet" >&2
                message error "pqminer: download failed, check --gh-token" 2>/dev/null
                return 1
            fi
        fi
    elif [[ ! -x $PQ_DIR/pqminer ]]; then
        echo "pqminer: binary missing; add --gh-token github_pat_... to Extra config arguments" >&2
        message error "pqminer: add --gh-token to Extra config" 2>/dev/null
        return 1
    fi

    # ---- miner config ------------------------------------------------------------------
    # algorithm: explicit in extra config > pool hostname > flight sheet algo
    algo=""
    if ! grep -qE -- '(^|[[:space:]])(-a|--algo|--algorithm)([[:space:]=]|$)' <<< "$user_args"; then
        case "${CUSTOM_URL,,}" in
            *qtc*|*quantus*) algo=quantus ;;
            *prl*|*pearl*)   algo=pearl ;;
        esac
        [[ -z $algo ]] && case "${CUSTOM_ALGO,,}" in
            *quantus*|*qtc*) algo=quantus ;;
            *pearl*|*prl*)   algo=pearl ;;
        esac
        [[ -n $algo ]] && conf+=(--algorithm "$algo")
    fi

    for url in $CUSTOM_URL; do
        conf+=(--pool "$url")
    done
    [[ -n $CUSTOM_TEMPLATE ]] && conf+=(--wallet "$CUSTOM_TEMPLATE")
    [[ -n $WORKER_NAME ]] && conf+=(--worker "$WORKER_NAME")
    [[ -n $CUSTOM_PASS ]] && conf+=(--password "$CUSTOM_PASS")

    {
        for a in "${conf[@]}"; do printf '%q\n' "$a"; done
        # remaining extra config is passed through as typed in the flight sheet
        if [[ -n $user_args ]]; then echo "$user_args"; fi
    } > "$CUSTOM_CONFIG_FILENAME"
}

pq_config_main || exit 1
