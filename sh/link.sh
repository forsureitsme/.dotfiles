#!/usr/bin/bash

echo Create symbolic links
BLA::start_loading_animation "${BLA_modern_metro[@]}"

for folder in "${foldersToLink[@]}"; do
    ln -s "$homeFolder/.dotfiles/$folder/" "$homeFolder/$(dirname $folder)"
done

BLA::stop_loading_animation
printf '\e[A\e[K' # Erase line of animation