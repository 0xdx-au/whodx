FROM alpine:3.19

# Enable community repo; install wayvnc, weston, etc.
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.19/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
        weston \
        wayvnc \
        python3 \
        py3-pip \
        supervisor \
        nginx \
        openssl \
        su-exec \
        shadow \
        ttf-dejavu \
        xdg-utils \
        libstdc++ \
    && adduser -D browser

# Create necessary directories and set permissions
RUN mkdir -p /tmp/xdg && \
    mkdir -p /home/browser/.tor-browser && \
    mkdir -p /home/browser/.config/wayland && \
    mkdir -p /etc/nginx/certs && \
    mkdir -p /app && \
    chown -R browser:browser /home/browser && \
    chown -R browser:browser /tmp/xdg
# Create a virtual environment and install websockify
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir websockify && \
    ln -s /opt/venv/bin/websockify /usr/local/bin/websockify

# Make sure the virtual environment is in PATH
ENV PATH="/opt/venv/bin:$PATH"

# Set environment variables for Wayland
ENV XDG_RUNTIME_DIR="/tmp/xdg"
ENV WAYLAND_DISPLAY="wayland-1"
ENV MOZ_ENABLE_WAYLAND=1

# Copy scripts/config
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY generate-certs /app/generate-certs
RUN chmod +x /app/generate-certs

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 42068
EXPOSE 42069

ENTRYPOINT ["/entrypoint.sh"]
