#!/usr/bin/bash

echo Install packages
paru -S nodejs pnpm webp-pixbuf-loader keyd mc lazygit bluetuith-bin zen-browser-bin vscodium --skipreview --batchinstall --noconfirm --quiet --needed

echo Install flatpaks
flatpaks=(
    "com.spotify.Client"
)

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
for flatpak in "${flatpaks[@]}"; do
    flatpak install -y flathub "$flatpak"
done
