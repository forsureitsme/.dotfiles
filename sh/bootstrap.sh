#!/usr/bin/bash

echo Bootstrap modules
modulesFolder="./modules"
mkdir -p $modulesFolder

blaFile="$modulesFolder/bash_loading_animations.sh"

if [ ! -f "$blaFile" ]; then
    wget --quiet -P "$modulesFolder" "https://raw.githubusercontent.com/Silejonu/bash_loading_animations/main/bash_loading_animations.sh"
fi
source "$blaFile"
trap BLA::stop_loading_animation SIGINT