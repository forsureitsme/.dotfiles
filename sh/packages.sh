#!/usr/bin/bash

set -euo pipefail

echo Install packages required by dotfiles

requiredPackages=(
    # Dotfiles shell/runtime tools
    nodejs-lts-jod
    pnpm
    jq
    flatpak

    # VPN/NAS scripts
    bitwarden-cli
    tailscale
    cifs-utils

    # Hyprland desktop commands used by this config
    waybar
    rofi
    mako
    network-manager-applet
    wob
    swaybg
    grim
    slurp
    swappy
    wl-clipboard
    playerctl
    brightnessctl
    wireplumber
    alacritty
    wlogout
    gnome-calculator
    swaylock-fancy-git
    polkit-kde-agent

    # Existing system utilities used by this setup
    webp-pixbuf-loader
    keyd
    mc
    lazygit
)

optionalPackages=(
    bluetuith-bin
    zen-browser-bin
    visual-studio-code-insiders-bin
)

pkgManager="${PKG_MANAGER:-paru}"

availableRequired=()
for pkg in "${requiredPackages[@]}"; do
    if "$pkgManager" -Si "$pkg" >/dev/null 2>&1; then
        availableRequired+=("$pkg")
    else
        echo "Warning: required package not found in repos/AUR: $pkg"
    fi
 done
 
 if [[ ${#availableRequired[@]} -gt 0 ]]; then
     if [[ "$pkgManager" == "paru" ]]; then
         paru -S "${availableRequired[@]}" --skipreview --batchinstall --noconfirm --quiet --needed --sudoloop --removemake --useask --ask 4
     else
         sudo pacman -S "${availableRequired[@]}" --needed --noconfirm
     fi
 fi
 
 availableOptional=()
 for pkg in "${optionalPackages[@]}"; do
     if "$pkgManager" -Si "$pkg" >/dev/null 2>&1; then
         availableOptional+=("$pkg")
     else
         echo "Info: optional package not found in repos/AUR: $pkg"
     fi
 done
 
 if [[ ${#availableOptional[@]} -gt 0 ]]; then
     echo Install optional desktop packages
     if [[ "$pkgManager" == "paru" ]]; then
         paru -S "${availableOptional[@]}" --skipreview --batchinstall --noconfirm --quiet --needed --sudoloop --removemake --useask --ask 4 || true
     else
         sudo pacman -S "${availableOptional[@]}" --needed --noconfirm || true
     fi
fi

echo Install flatpaks
flatpaks=(
    "com.spotify.Client"
)

if command -v flatpak >/dev/null 2>&1; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    for flatpak in "${flatpaks[@]}"; do
        flatpak install -y flathub "$flatpak"
    done
else
    echo "Info: flatpak command not available, skipping flatpak install"
fi
