#!/bin/sh
set -e

# Setup runtime directory with proper ownership and permissions
mkdir -p /run/user/1000
chmod 700 /run/user/1000
chown browser:browser /run/user/1000

# Create required directories
mkdir -p /home/browser/.tor-browser
mkdir -p /home/browser/.config/wayland
mkdir -p /app/novnc

# Set up proper permissions
chown -R browser:browser /home/browser
[ -d /opt/tor-browser ] && chown -R browser:browser /opt/tor-browser

# Set environment variables
export XDG_RUNTIME_DIR="/run/user/1000"
export WAYLAND_DISPLAY="wayland-1"
export MOZ_ENABLE_WAYLAND=1
export DISPLAY=""

# Generate self-signed certs if they don't exist
/app/generate-certs

# Create supervisor directory if it doesn't exist
mkdir -p /etc/supervisor

# Output system status for debugging
echo "[+] Starting browser container with Wayland support"
echo "[+] XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
ls -la $XDG_RUNTIME_DIR
id browser

# Start everything via supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
