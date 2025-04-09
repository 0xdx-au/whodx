FROM debian:bullseye-slim

LABEL org.opencontainers.image.title="whodx"
LABEL org.opencontainers.image.description="TOR-only, self-destructing Wayland remote desktop"
LABEL org.opencontainers.image.authors="you@example.com"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive

# Install base packages + build tools for wayvnc
RUN apt-get update && apt-get install -y \
    git curl wget bash sudo python3 net-tools procps dialog \
    weston xwayland tor supervisor openssl torsocks \
    dbus-x11 libpam-systemd cryptsetup util-linux \
    build-essential meson ninja-build pkg-config cmake \
    libjansson-dev \
    libpixman-1-dev libxkbcommon-dev libdrm-dev libwayland-dev \
    libxcb1-dev libxcb-util0-dev libxcb-ewmh-dev \
    libxcb-icccm4-dev libxcb-image0-dev libxcb-shm0-dev \
    libxcb-xfixes0-dev libxcb-xkb-dev libxkbcommon-x11-dev \
    libxcb-randr0-dev libxcb-render-util0-dev \
    libxcb-cursor-dev libxcb-keysyms1-dev \
    libavahi-client-dev libavahi-common-dev \
    libssl-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Build wayvnc from source
RUN git clone https://github.com/any1/wayvnc.git /opt/wayvnc && \
    cd /opt/wayvnc && \
    meson setup build && \
    ninja -C build && \
    ninja -C build install

# noVNC
RUN mkdir -p /opt/novnc && \
    git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

# HTTPS cert
COPY generate-cert.sh /opt/generate-cert.sh
RUN chmod +x /opt/generate-cert.sh && /opt/generate-cert.sh

# Configs
COPY torrc /etc/tor/torrc
COPY weston.ini /etc/xdg/weston/weston.ini
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

CMD ["/entrypoint.sh"]
