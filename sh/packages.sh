#!/usr/bin/bash

echo Install script dependencies
BLA::start_loading_animation "${BLA_modern_metro[@]}"
paru -S nodejs webp-pixbuf-loader --noconfirm --quiet --print | sed 1,2d >/dev/null
BLA::stop_loading_animation
printf '\e[A\e[K' # Erase line of animation