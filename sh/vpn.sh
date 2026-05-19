#!/usr/bin/bash

set -euo pipefail

echo Configure VPN: Using Tailscale as primary VPN

# WireGuard has been removed in favor of Tailscale.
# Tailscale is now the primary VPN solution.

if ! systemctl is-enabled tailscaled >/dev/null 2>&1; then
    echo "Enabling Tailscale..."
    sudo systemctl enable tailscaled
fi

if ! systemctl is-active tailscaled >/dev/null 2>&1; then
    echo "Starting Tailscale..."
    sudo systemctl start tailscaled
fi

echo "VPN setup completed: Tailscale is running"
echo "To connect: tailscale up"
