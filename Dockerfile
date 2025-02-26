# Dockerfile for whodx: Ephemeral Tor Browser Kiosk

# Use the official Ubuntu base image
FROM ubuntu:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV USER=cn
ENV HOME=/home/$USER

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    torbrowser-launcher \
    xorg \
    x11vnc \
    novnc \
    supervisor \
    sudo \
    wget \
    unzip \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash $USER && echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install websockify for noVNC
RUN pip3 install websockify

# Download and set up noVNC
RUN mkdir -p /opt/novnc/utils/websockify && \
    wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.3.0.tar.gz | tar xz --strip-components=1 -C /opt/novnc && \
    ln -s /opt/novnc/vnc.html /opt/novnc/index.html

# Set up supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set up entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the noVNC port
EXPOSE 8080

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
