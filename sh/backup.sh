#!/usr/bin/bash

echo Backup affected folders

now=$(date +"%Y-%m-%d_%H-%M-%S")
backupFolder="./backup/$now"

for folder in "${foldersToLink[@]}"; do
    if [[ -L "$homeFolder/$folder" ]]; then
        continue
    fi
    mkdir -p "$backupFolder/$(dirname "$folder")"
    mv "$homeFolder/$folder" "$backupFolder/$folder"
done
