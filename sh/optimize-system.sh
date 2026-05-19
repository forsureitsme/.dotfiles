#!/usr/bin/bash

set -euo pipefail

echo "Applying system boot optimizations"

# Blacklist intel_punit_ipc module (Chromebook hardware, spams logs with unrecoverable errors)
blacklistFile="/etc/modprobe.d/blacklist-intel-punit.conf"
if [[ ! -f "$blacklistFile" ]] || ! grep -q '^blacklist intel_punit_ipc$' "$blacklistFile"; then
    echo "Adding intel_punit_ipc to module blacklist"
    echo "blacklist intel_punit_ipc" | sudo tee "$blacklistFile" >/dev/null
fi

# Disable fsck on /boot mountpoint if it exists in fstab
bootLineCount=$(grep -E '^[[:space:]]*[^#].*[[:space:]]/boot(/|[[:space:]]|$)' /etc/fstab | wc -l || true)
if [[ "$bootLineCount" -gt 0 ]]; then
    tmpFile="$(mktemp)"
    awk 'BEGIN{changed=0}
        /^[[:space:]]*#/ {print; next}
        changed==0 && $2=="/boot" && $6==2 { $6=0; changed=1; print; next }
        changed==0 && $2~"^/boot/" && $6==2 { $6=0; changed=1; print; next }
        {print}
    ' /etc/fstab >"$tmpFile"
    if ! cmp -s "$tmpFile" /etc/fstab; then
        echo "Disabling fsck on /boot partition in /etc/fstab"
        sudo mv "$tmpFile" /etc/fstab
    else
        rm -f "$tmpFile"
    fi
fi

echo "System optimizations complete"
