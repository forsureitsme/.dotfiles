#!/usr/bin/bash

echo Configure git user
BLA::start_loading_animation "${BLA_modern_metro[@]}"

git config --global user.name "Pedro Cardoso da Silva"
git config --global user.email forsureitsme@gmail.com

BLA::stop_loading_animation
printf '\e[A\e[K' # Erase line of animation