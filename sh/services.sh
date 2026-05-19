#!/usr/bin/bash

set -euo pipefail

echo Configure services for this machine

sudo systemctl disable avahi-daemon.service
sudo systemctl enable --now tailscaled.service

