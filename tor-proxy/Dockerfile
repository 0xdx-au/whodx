FROM alpine:3.19

# Enable community repo and install dependencies
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.19/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories && \
    apk update && \
    # Install required packages including shadow for user management
    apk add --no-cache netcat-openbsd curl tor procps shadow && \
    rm -rf /var/cache/apk/*

# Create a dedicated tor user/group
RUN addgroup -S torproxy && \
    adduser -S -D -H -h /var/lib/tor -s /sbin/nologin -G torproxy -g "Tor Proxy User" torproxy && \
    # Create necessary directories with proper permissions
    mkdir -p /var/log/tor /var/lib/tor /etc/tor && \
    chown -R torproxy:torproxy /var/log/tor /var/lib/tor /etc/tor && \
    chmod 700 /var/log/tor /var/lib/tor

# Copy in our torrc and update it
COPY torrc /etc/tor/torrc
RUN echo "Log notice file /var/log/tor/notices.log" >> /etc/tor/torrc && \
    echo "DataDirectory /var/lib/tor" >> /etc/tor/torrc && \
    # DO NOT add User directive to torrc - we'll use Docker's USER directive instead
    # Ensure torrc has the right ownership
    chown torproxy:torproxy /etc/tor/torrc

# Create more resilient healthcheck script
RUN echo '#!/bin/sh' > /usr/local/bin/healthcheck.sh && \
    echo 'set -e' >> /usr/local/bin/healthcheck.sh && \
    echo '# Check if SOCKS port is open' >> /usr/local/bin/healthcheck.sh && \
    echo 'nc -z localhost 9050 || exit 1' >> /usr/local/bin/healthcheck.sh && \
    echo '' >> /usr/local/bin/healthcheck.sh && \
    echo '# Check bootstrap status only if log file exists' >> /usr/local/bin/healthcheck.sh && \
    echo 'if [ -f /var/log/tor/notices.log ]; then' >> /usr/local/bin/healthcheck.sh && \
    echo '  if grep -q "Bootstrapped 100" /var/log/tor/notices.log; then' >> /usr/local/bin/healthcheck.sh && \
    echo '    echo "Tor is fully bootstrapped"' >> /usr/local/bin/healthcheck.sh && \
    echo '    exit 0' >> /usr/local/bin/healthcheck.sh && \
    echo '  elif grep -q "Bootstrapped" /var/log/tor/notices.log; then' >> /usr/local/bin/healthcheck.sh && \
    echo '    # If bootstrapping is in progress, report healthy during startup period' >> /usr/local/bin/healthcheck.sh && \
    echo '    echo "Tor is bootstrapping..."' >> /usr/local/bin/healthcheck.sh && \
    echo '    exit 0' >> /usr/local/bin/healthcheck.sh && \
    echo '  else' >> /usr/local/bin/healthcheck.sh && \
    echo '    echo "No bootstrap progress found in logs"' >> /usr/local/bin/healthcheck.sh && \
    echo '    # During startup, still report healthy' >> /usr/local/bin/healthcheck.sh && \
    echo '    exit 0' >> /usr/local/bin/healthcheck.sh && \
    echo '  fi' >> /usr/local/bin/healthcheck.sh && \
    echo 'else' >> /usr/local/bin/healthcheck.sh && \
    echo '  echo "Log file not found, assuming initialization in progress"' >> /usr/local/bin/healthcheck.sh && \
    echo '  # During startup, just check if the process is running' >> /usr/local/bin/healthcheck.sh && \
    echo '  pgrep -x tor > /dev/null || exit 1' >> /usr/local/bin/healthcheck.sh && \
    echo '  exit 0' >> /usr/local/bin/healthcheck.sh && \
    echo 'fi' >> /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Ensure volumes have proper permissions at runtime
VOLUME ["/var/log/tor", "/var/lib/tor"]

# Expose the Tor SOCKS port
EXPOSE 9050

# Switch to the torproxy user for runtime
USER torproxy

# Run Tor with the config file
CMD ["tor", "-f", "/etc/tor/torrc"]
