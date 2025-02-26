#!/usr/bin/env bash
set -e

mkdir -p /opt
cd /opt

# Only generate a new certificate if one doesn't exist
if [ ! -f selfsigned.crt ] || [ ! -f selfsigned.key ]; then
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout selfsigned.key \
    -out selfsigned.crt \
    -days 31 \
    -subj "/C=US/ST=whodx/L=newphone/O=whodx/CN=localhost"
fi

# Adjust ownership and permissions so non-root can use the cert for noVNC
# (allow appuser to read the TLS certificate and key)
chown appuser:appuser /opt/selfsigned.crt /opt/selfsigned.key
chmod 644 /opt/selfsigned.crt
chmod 600 /opt/selfsigned.key
