#!/usr/bin/bash

set -euo pipefail

# NAS topology is intentionally configured in-script.
NAS_HOST="truenas"
NAS_SHARES=(
    "Projects"
)

echo Configure NAS mounts from Bitwarden credentials

dotfilesDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
secretsFile="$dotfilesDir/.secrets"

if [[ ! -f "$secretsFile" ]]; then
    echo "Skipping NAS setup: .secrets file not found at $secretsFile"
    return 0 2>/dev/null || exit 0
fi

# shellcheck source=/dev/null
source "$secretsFile"

requiredVars=(BW_CLIENTID BW_CLIENTSECRET BW_PASSWORD)
for varName in "${requiredVars[@]}"; do
    if [[ -z "${!varName:-}" ]]; then
        echo "Skipping NAS setup: missing $varName in .secrets"
        return 0 2>/dev/null || exit 0
    fi
done

if [[ -z "${BW_NAS_ITEM_NAME:-}" ]]; then
    echo "Skipping NAS setup: missing BW_NAS_ITEM_NAME in .secrets"
    return 0 2>/dev/null || exit 0
fi

if ! command -v bw >/dev/null 2>&1; then
    echo "Skipping NAS setup: bitwarden-cli (bw) not installed"
    return 0 2>/dev/null || exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Skipping NAS setup: jq not installed"
    return 0 2>/dev/null || exit 0
fi

mountRoot="$HOME/nas"
credentialsFile="$HOME/.nas-credentials"
userId="$(id -u)"
groupId="$(id -g)"
tailscaleReadyUnit="tailscale-nas-ready.service"

if ! sudo -n true >/dev/null 2>&1; then
    echo "Skipping NAS setup: sudo authentication unavailable; run from install.sh"
    return 0 2>/dev/null || exit 0
fi

export BW_CLIENTID
export BW_CLIENTSECRET
export BW_PASSWORD
bw logout >/dev/null 2>&1 || true
bw login --apikey >/dev/null
export BW_SESSION="$(bw unlock --passwordenv BW_PASSWORD --raw)"

mapfile -t nasItemIds < <(bw list items --search "$BW_NAS_ITEM_NAME" | jq -r --arg NAME "$BW_NAS_ITEM_NAME" '.[] | select((.name | ascii_downcase) == ($NAME | ascii_downcase)) | .id')
if [[ "${#nasItemIds[@]}" -eq 0 ]]; then
    echo "NAS setup failed: no Bitwarden item found with exact case-insensitive name '$BW_NAS_ITEM_NAME'"
    bw lock >/dev/null 2>&1 || true
    bw logout >/dev/null 2>&1 || true
    return 1 2>/dev/null || exit 1
fi
if [[ "${#nasItemIds[@]}" -gt 1 ]]; then
    echo "NAS setup failed: multiple Bitwarden items match exact case-insensitive name '$BW_NAS_ITEM_NAME':"
    printf '  - %s\n' "${nasItemIds[@]}"
    bw lock >/dev/null 2>&1 || true
    bw logout >/dev/null 2>&1 || true
    return 1 2>/dev/null || exit 1
fi

nasItemJson="$(bw get item "${nasItemIds[0]}")"
nasItemLabel="$BW_NAS_ITEM_NAME"

nasUsername="$(printf '%s' "$nasItemJson" | jq -r '.login.username // empty')"
nasPassword="$(printf '%s' "$nasItemJson" | jq -r '.login.password // empty')"
nasDomain="$(printf '%s' "$nasItemJson" | jq -r '.fields[]? | select((.name | ascii_downcase) == "domain") | .value' | head -n 1)"

if [[ -z "$nasUsername" || -z "$nasPassword" ]]; then
    echo "NAS setup failed: Bitwarden item '$nasItemLabel' is missing login username/password"
    bw lock >/dev/null 2>&1 || true
    bw logout >/dev/null 2>&1 || true
    return 1 2>/dev/null || exit 1
fi

mkdir -p "$mountRoot"

{
    printf 'username=%s\n' "$nasUsername"
    printf 'password=%s\n' "$nasPassword"
    if [[ -n "$nasDomain" ]]; then
        printf 'domain=%s\n' "$nasDomain"
    fi
} >"$credentialsFile"
chmod 600 "$credentialsFile"

mountUnitNames=()
tailscaleReadyUnitContent=$(cat <<EOF
[Unit]
Description=Wait until Tailscale can reach NAS prerequisites
After=network-online.target tailscaled.service
Wants=network-online.target tailscaled.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/bash -c 'set -euo pipefail; for _ in {1..30}; do if /usr/bin/systemctl is-active --quiet tailscaled && /usr/bin/tailscale ip -4 >/dev/null 2>&1 && /usr/bin/getent ahostsv4 ${NAS_HOST} >/dev/null 2>&1; then exit 0; fi; sleep 2; done; echo "Timed out waiting for Tailscale NAS readiness" >&2; exit 1'
EOF
)
automountUnitNames=()

writeSystemdUnit() {
    local unitName="$1"
    local unitContent="$2"
    local unitPath="/etc/systemd/system/$unitName"
    local tmpFile currentFile

    tmpFile="$(mktemp)"
    currentFile="$(mktemp)"

    printf '%s' "$unitContent" >"$tmpFile"
    sudo -n cat "$unitPath" >"$currentFile" 2>/dev/null || true

    if cmp -s "$tmpFile" "$currentFile"; then
        rm -f "$tmpFile" "$currentFile"
        return 0
    fi

    sudo -n install -m 0644 "$tmpFile" "$unitPath"
    rm -f "$tmpFile" "$currentFile"
}

writeSystemdUnit "$tailscaleReadyUnit" "$tailscaleReadyUnitContent"

for share in "${NAS_SHARES[@]}"; do
    mountPoint="$mountRoot/$share"
    mkdir -p "$mountPoint"

    mountUnitName="$(systemd-escape --path "$mountPoint").mount"
    automountUnitName="$(systemd-escape --path "$mountPoint").automount"
    mountUnitNames+=("$mountUnitName")
    automountUnitNames+=("$automountUnitName")

    cifsWhat="//${NAS_HOST}/${share}"
    cifsOptions="credentials=${credentialsFile},uid=${userId},gid=${groupId},iocharset=utf8,_netdev,nofail"
    mountUnitContent=$(cat <<EOF
[Unit]
Description=Mount NAS share ${share}
After=network-online.target tailscaled.service ${tailscaleReadyUnit}
Wants=network-online.target tailscaled.service
Requires=${tailscaleReadyUnit}

[Mount]
What=${cifsWhat}
Where=${mountPoint}
Type=cifs
Options=${cifsOptions}
EOF
)

    automountUnitContent=$(cat <<EOF
[Unit]
Description=Automount NAS share ${share}
After=network-online.target tailscaled.service
Wants=network-online.target tailscaled.service

[Automount]
Where=${mountPoint}
TimeoutIdleSec=600

[Install]
WantedBy=multi-user.target
EOF
)

    writeSystemdUnit "$mountUnitName" "$mountUnitContent"
    writeSystemdUnit "$automountUnitName" "$automountUnitContent"
done

sudo systemctl daemon-reload
for mountUnitName in "${mountUnitNames[@]}"; do
    sudo -n systemctl disable "$mountUnitName" >/dev/null 2>&1 || true
done
for automountUnitName in "${automountUnitNames[@]}"; do
    sudo -n systemctl enable --now "$automountUnitName"
done

bw lock >/dev/null 2>&1 || true
bw logout >/dev/null 2>&1 || true
unset BW_SESSION

echo "NAS setup completed for shares: ${NAS_SHARES[*]}"
