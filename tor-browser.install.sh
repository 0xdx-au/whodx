#!/usr/bin/env bash
set -e

TOR_URL="https://dist.torproject.org/torbrowser/14.0.6/tor-browser-linux-x86_64-14.0.6.tar.xz"

cd /opt

echo "Downloading Tor Browser from: $TOR_URL"
wget --quiet "$TOR_URL"

FILENAME="tor-browser-linux-x86_64-14.0.6.tar.xz"
echo "Extracting $FILENAME..."
tar -xf "$FILENAME"
rm "$FILENAME"

if [ ! -d "tor-browser" ]; then
  mv tor-browser* tor-browser
fi

chown -R appuser:appuser /opt/tor-browser
