#!/usr/bin/bash

set -euo pipefail

pkgManager=""
if command -v paru >/dev/null 2>&1; then
    pkgManager=paru
elif command -v pacman >/dev/null 2>&1; then
    pkgManager=pacman
else
    echo "No supported package manager found. Install paru or pacman."
    exit 1
fi
export PKG_MANAGER="$pkgManager"

userName="${SUDO_USER:-$(logname)}"
homeFolder="$(getent passwd "$userName" | cut -d: -f6)"
homeFolder="${homeFolder:-/home/$userName}"
cd "$(dirname "$0")" >/dev/null || exit 1
foldersToLink=(.config/*)

echo "Sudo authentication is required for system setup steps"
if ! sudo -k; then
    echo "Failed to reset sudo credential cache"
    exit 1
fi

if ! sudo -v; then
    echo "Sudo authentication failed; aborting install"
    exit 1
fi

source "./sh/git.sh"
source "./sh/backup.sh"
source "./sh/packages.sh"
source "./sh/services.sh"

source "./sh/vpn.sh"
source "./sh/nas.sh"

source "./sh/optimize-system.sh"

source "./sh/link.sh"
source "./sh/vscodium.sh"

cd - >/dev/null || exit
