#!/usr/bin/bash

echo Remove bloat
BLA::start_loading_animation "${BLA_modern_metro[@]}"
paru -R fastfetch firefox --noconfirm --quiet --print | sed 1,2d >/dev/null
BLA::stop_loading_animation
printf '\e[A\e[K' # Erase line of animation

echo Install script dependencies
BLA::start_loading_animation "${BLA_modern_metro[@]}"
paru -S nodejs pnpm webp-pixbuf-loader keyd spotify mc lazygit bluetuith-bin zen-browser-bin vscodium --noconfirm --quiet --print | sed 1,2d >/dev/null
BLA::stop_loading_animation
printf '\e[A\e[K' # Erase line of animation