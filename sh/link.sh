#!/usr/bin/bash

echo Create symbolic links

for folder in "${foldersToLink[@]}"; do
    expectedTarget="$homeFolder/.dotfiles/$folder/"
    linkPath="$homeFolder/$folder"
    if [[ -L "$linkPath" ]]; then
        if [[ "$(readlink "$linkPath")" == "$expectedTarget" ]]; then
            continue
        else
            echo "Warning: $linkPath exists but points to an unexpected target, skipping"
            continue
        fi
    elif [[ -e "$linkPath" ]]; then
        echo "Warning: $linkPath exists and is not a symlink, skipping"
        continue
    fi
    ln -s "$expectedTarget" "$linkPath"
done
