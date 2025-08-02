#!/usr/bin/bash

if ! command -v paru >/dev/null 2>&1; then
    echo "paru could not be found"
    exit 1
fi

homeFolder=/home/$(logname)
cd "$(dirname "$0")" >/dev/null || exit 1
foldersToLink=(.config/*)

source "./sh/git.sh" &
source "./sh/packages.sh" &
source "./sh/backup.sh" &
wait

source "./sh/link.sh"

cd - >/dev/null || exit
