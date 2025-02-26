#!/usr/bin/env bash
set -e

mkdir -p /opt
cd /opt

if [ ! -f selfsigned.crt ] || [ ! -f selfsigned.key ]; then
    openssl req -x509 -nodes -newkey rsa:2048 \
      -keyout selfsigned.key \
      -out selfsigned.crt \
      -days 1 \
      -subj "/C=US/ST=Denial/L=Nowhere/O=whodx/CN=localhost"
fi
