#!/bin/bash
# entrypoint.sh: Entry point script for whodx

# Start Xorg server
Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /var/log/xorg.log -config /etc/X11/xorg.conf :0 &

# Wait for Xorg to start
sleep 2

# Start x11vnc server
x11vnc -display :0 -forever -nopw -shared -rfbport 5900 &

# Start websockify for noVNC
websockify --web=/opt/novnc --cert=/etc/ssl/certs/novnc.pem 8080 localhost:5900 &

# Launch Tor Browser
sudo -u $USER torbrowser-launcher --no-sandbox &

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
