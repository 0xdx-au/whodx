FROM debian:bullseye-slim

LABEL maintainer="whodx-secure@example.com"
LABEL description="TOR-only, self-destructing Wayland remote desktop"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    weston \
    wayvnc \
    dbus-x11 \
    tor \
    supervisor \
    openssl \
    curl \
    wget \
    sudo \
    python3 \
    net-tools \
    bash \
    git \
    xwayland \
    libpam-systemd \
    cryptsetup \
    util-linux \
    dialog \
    procps \
    torsocks \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/novnc && \
    git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone https://github.com/novnc/websockify /opt/novnc/utils/websockify

COPY generate-cert.sh /opt/generate-cert.sh
RUN chmod +x /opt/generate-cert.sh && /opt/generate-cert.sh

COPY torrc /etc/tor/torrc
COPY weston.ini /etc/xdg/weston/weston.ini
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

CMD ["/entrypoint.sh"]
