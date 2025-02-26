#!/usr/bin/env bash
set -e

export DISPLAY=:1

echo "================================================="
echo "whodx container running: Tor Browser (non-root) + Xorg dummy!"
echo "Access URL: https://localhost:9491/vnc.html"
echo "Session self-destructs in 30 minutes."
echo "================================================="

# 1) Start Tor in the background
echo "[1/7] Starting Tor..."
tor -f /etc/tor/torrc &
TOR_PID=$!

# 2) Start the Xorg dummy server with RandR in the background
echo "[2/7] Starting Xorg on :1..."
Xorg :1 -config /etc/X11/xorg-dummy.conf -noreset -listen tcp +extension RANDR -logfile /var/log/Xorg.log &
XORG_PID=$!

# 3) Wait 3 seconds for Xorg to be ready, then disable X authentication
echo "[3/7] Waiting 3 seconds for Xorg to start, then running 'xhost +'..."
sleep 3
xhost + || echo "WARNING: 'xhost +' failed."

# 4) Start Openbox as non-root user in the background
echo "[4/7] Starting Openbox as 'appuser'..."
sudo -u appuser DISPLAY=:1 HOME=/home/appuser openbox &
OPENBOX_PID=$!

# 5) Start x11vnc (without the unsupported -resize, but with -ncache 10)
echo "[5/7] Starting x11vnc on port 5900..."
x11vnc -display :1 -forever -shared -rfbport 5900 -nopw -listen 0.0.0.0 -ncache 10 &
X11VNC_PID=$!

# 6) Start noVNC (which proxies from 0.0.0.0:8443 to 127.0.0.1:5900 with SSL/TLS)
echo "[6/7] Starting noVNC on port 8443..."
websockify --web=/usr/share/novnc/ 0.0.0.0:8443 127.0.0.1:5900 \
  --cert=/opt/selfsigned.crt \
  --key=/opt/selfsigned.key \
  --ssl-only &
NOVNC_PID=$!

# 7) After a short delay, launch Tor Browser as non-root
echo "[7/7] Launching Tor Browser as 'appuser' in 5 seconds..."
sleep 5
sudo -u appuser bash -c "cd /opt/tor-browser && ./start-tor-browser.desktop --allow-remote" || true

# Self-destruct after 30 minutes
(
  sleep 1800
  echo "Time's up! Self-destructing container..."
  kill -TERM 1
) &

# Wait on background processes so the container remains alive
wait $TOR_PID || echo "Tor exited with code $?"
wait $XORG_PID || echo "Xorg exited with code $?"
wait $OPENBOX_PID || echo "Openbox exited with code $?"
wait $X11VNC_PID || echo "x11vnc exited with code $?"
wait $NOVNC_PID || echo "noVNC exited with code $?"
