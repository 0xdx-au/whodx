#!/usr/bin/env bash
set -e

export DISPLAY=:1

echo "================================================="
echo "whodx container running: Tor Browser (non-root) + Xorg dummy!"
echo "Access URL: https://localhost:9491/vnc.html"
echo "Session self-destructs in 30 minutes."
echo "================================================="

# 1) Start Tor in background
echo "[1/6] Starting Tor..."
tor -f /etc/tor/torrc &
TOR_PID=$!

# 2) Start Xorg dummy server
echo "[2/6] Starting Xorg on :1..."
Xorg :1 -config /etc/X11/xorg-dummy.conf -noreset -listen tcp +extension RANDR -logfile /var/log/Xorg.log &
XORG_PID=$!

# 3) Wait 3s, then run xhost + to disable X authentication
echo "[3/6] Disabling X authentication with 'xhost +'..."
sleep 3
xhost + || echo "WARNING: xhost + failed."

# 4) Start openbox as 'appuser'
echo "[4/6] Starting Openbox as 'appuser'..."
sudo -u appuser DISPLAY=:1 HOME=/home/appuser openbox &
OPENBOX_PID=$!

# 5) Start x11vnc without '-resize' to avoid crash
echo "[5/6] Starting x11vnc (no -resize) on port 5900..."
x11vnc -display :1 -forever -shared -rfbport 5900 \
       -nopw -listen 0.0.0.0 &
X11VNC_PID=$!

# Start noVNC => wraps 127.0.0.1:5900 -> :8443
echo "[5b/6] Starting noVNC on port 8443..."
websockify --web=/usr/share/novnc/ 0.0.0.0:8443 127.0.0.1:5900 \
  --cert=/opt/selfsigned.crt \
  --key=/opt/selfsigned.key \
  --ssl-only &
NOVNC_PID=$!

# 6) After 5s, launch Tor Browser as 'appuser'
echo "[6/6] Launching Tor Browser in 5s..."
sleep 5
sudo -u appuser bash -c "cd /opt/tor-browser && ./start-tor-browser.desktop --allow-remote" || true

# Self-destruct after 30 minutes
(
  sleep 1800
  echo "Time's up! Self-destructing..."
  kill -TERM 1
) &

# Wait on background processes to keep container alive
wait $TOR_PID || echo "Tor exited with code $?"
wait $XORG_PID || echo "Xorg exited with code $?"
wait
