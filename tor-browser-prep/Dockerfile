FROM alpine:3.19

# Enable community repo if needed for extra packages
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.19/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache curl xz file torsocks netcat-openbsd && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /init
COPY download-tor.sh /init/download-tor.sh
RUN chmod +x /init/download-tor.sh

ENTRYPOINT ["/init/download-tor.sh"]
