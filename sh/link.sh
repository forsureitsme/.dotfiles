#!/usr/bin/bash

echo Create symbolic links

for folder in "${foldersToLink[@]}"; do
    ln -s "$homeFolder/.dotfiles/$folder/" "$homeFolder/$(dirname $folder)"
done
