FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1) Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    xserver-xorg-core \
    xserver-xorg-video-dummy \
    x11-xserver-utils \
    sudo \
    x11vnc \
    novnc \
    websockify \
    wget \
    gnupg \
    ca-certificates \
    openssl \
    openbox \
    procps \
    tor \
    tor-geoipdb \
    xz-utils \
    zenity \
    kdialog \
    gxmessage && rm -rf /var/lib/apt/lists/*

# 2) Create a non-root user 'appuser'
RUN useradd -m -d /home/appuser -s /bin/bash appuser

# 3) Copy local files into the image
COPY xorg-dummy.conf /etc/X11/xorg-dummy.conf
COPY generate-cert.sh /opt/generate-cert.sh
COPY tor-browser.install.sh /opt/tor-browser.install.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# 4) Make scripts executable
RUN chmod +x /opt/generate-cert.sh \
    && chmod +x /opt/tor-browser.install.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# 5) Generate self-signed certificate and install Tor Browser
RUN /opt/generate-cert.sh 
RUN /opt/tor-browser.install.sh

# 6) Adjust ownership so 'appuser' can access necessary files
RUN chown -R appuser:appuser /tmp || true 
RUN chown -R appuser:appuser /opt/tor-browser 
RUN chown -R appuser:appuser /home/appuser

# 7) Expose noVNC port
EXPOSE 8443

# 8) Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
