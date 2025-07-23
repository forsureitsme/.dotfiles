#!/usr/bin/bash

echo Backup affected folders
BLA::start_loading_animation "${BLA_modern_metro[@]}"

now=$(date +"%Y-%m-%d_%H-%M-%S")
backupFolder="./backup/$now"

for folder in "${foldersToLink[@]}"; do
    mkdir -p "$backupFolder/$(dirname $folder)"
    mv "$homeFolder/$folder" "$backupFolder/$folder"
done

BLA::stop_loading_animation
printf '\e[A\e[K' # Erase line of animation