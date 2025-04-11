#!/bin/sh
set -e

TOR_VER="13.0.13"
ARCHIVE_URL="https://www.torproject.org/dist/torbrowser/${TOR_VER}/tor-browser-linux64-${TOR_VER}_ALL.tar.xz"
MAX_RETRIES=15
RETRY_DELAY=5
TOR_PROXY_HOST="tor-proxy"
TOR_SOCKS_PORT=9050
TOR_DNS_PORT=5353

# Function to get Tor proxy IP address
get_tor_proxy_ip() {
  # Try different methods to resolve the IP
  if command -v getent >/dev/null 2>&1; then
    TOR_IP=$(getent hosts $TOR_PROXY_HOST | awk '{ print $1 }')
  elif command -v nslookup >/dev/null 2>&1; then
    TOR_IP=$(nslookup $TOR_PROXY_HOST | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  elif command -v dig >/dev/null 2>&1; then
    TOR_IP=$(dig +short $TOR_PROXY_HOST)
  elif command -v host >/dev/null 2>&1; then
    TOR_IP=$(host $TOR_PROXY_HOST | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  fi

  # If all else fails, try to ping and capture IP
  if [ -z "$TOR_IP" ] && command -v ping >/dev/null 2>&1; then
    TOR_IP=$(ping -c 1 $TOR_PROXY_HOST | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  fi

  echo "$TOR_IP"
}

# Configure logging function
log_info() {
  echo "[+] $1"
}

log_error() {
  echo "[-] Error: $1"
}

log_warn() {
  echo "[!] Warning: $1"
}

log_debug() {
  echo "[*] Debug: $1"
}

# Wait for Tor proxy to be available
log_info "Waiting for Tor proxy to be ready..."
retries=0
until nc -z $TOR_PROXY_HOST $TOR_SOCKS_PORT || [ $retries -eq $MAX_RETRIES ]; do
  echo "Waiting for Tor proxy... (retry $retries/$MAX_RETRIES in ${RETRY_DELAY}s)"
  sleep $RETRY_DELAY
  retries=$((retries + 1))
done

if [ $retries -eq $MAX_RETRIES ]; then
  log_error "Tor proxy is not available after $MAX_RETRIES retries"
  exit 1
fi

log_info "Tor proxy SOCKS port is available! Testing DNS port..."

# Check if DNS port is available
retries=0
until nc -z $TOR_PROXY_HOST $TOR_DNS_PORT || [ $retries -eq $MAX_RETRIES ]; do
  echo "Waiting for Tor DNS... (retry $retries/$MAX_RETRIES in ${RETRY_DELAY}s)"
  sleep $RETRY_DELAY
  retries=$((retries + 1))
done

if [ $retries -eq $MAX_RETRIES ]; then
  log_warn "Tor DNS port is not available, will use SOCKS proxy only"
fi

# Get Tor proxy IP address
TOR_IP=$(get_tor_proxy_ip)
if [ -z "$TOR_IP" ]; then
  log_error "Could not resolve Tor proxy IP address"
  log_debug "Network configuration:"
  ip addr
  log_debug "Hosts file:"
  cat /etc/hosts
  exit 1
fi

log_info "Resolved Tor proxy IP: $TOR_IP"

# Configure system to use Tor for DNS
log_info "Configuring DNS to use Tor..."
echo "nameserver $TOR_IP" > /etc/resolv.conf
echo "options attempts:2" >> /etc/resolv.conf

# Configure torsocks
export TORSOCKS_CONF_FILE="/etc/tor/torsocks.conf"
cat > "$TORSOCKS_CONF_FILE" << EOF
TorAddress $TOR_IP
TorPort $TOR_SOCKS_PORT
AllowInbound 1
AllowOutbound 1
OnionAddrRange 127.0.0.1/8
EOF

# Wait for Tor to be fully bootstrapped
log_info "Waiting for Tor network to be bootstrapped..."
retries=0
bootstrap_success=0

while [ $retries -lt $MAX_RETRIES ] && [ $bootstrap_success -eq 0 ]; do
  # Try to check if Tor is working with a simple test
  if curl --socks5-hostname $TOR_IP:$TOR_SOCKS_PORT --socks5-gssapi-nec \
          -s -m 30 --retry 3 --retry-delay 2 \
          https://check.torproject.org/ | grep -q "Congratulations"; then
    bootstrap_success=1
    log_info "Tor network is ready!"
  else
    echo "Waiting for Tor network to be ready... (retry $retries/$MAX_RETRIES in ${RETRY_DELAY}s)"
    sleep $RETRY_DELAY
    retries=$((retries + 1))
  fi
done

if [ $bootstrap_success -eq 0 ]; then
  log_warn "Could not verify Tor network, but will try to proceed"
  log_debug "Testing basic connectivity..."
  curl --socks5-hostname $TOR_IP:$TOR_SOCKS_PORT -v --connect-timeout 30 https://check.torproject.org/ || true
fi

# Try downloading with a retry mechanism
log_info "Downloading Tor Browser $TOR_VER through Tor..."
retries=0
download_success=0

while [ $retries -lt $MAX_RETRIES ] && [ $download_success -eq 0 ]; do
  if curl --socks5-hostname $TOR_IP:$TOR_SOCKS_PORT --socks5-gssapi-nec \
          -fL -m 600 --retry 5 --retry-delay 10 --retry-max-time 300 \
          -o /tmp/tor-browser.tar.xz "$ARCHIVE_URL"; then
    download_success=1
  else
    log_warn "Download attempt $retries failed, retrying in ${RETRY_DELAY}s..."
    # Try to resolve the domain to check DNS
    if [ $retries -eq 3 ]; then
      log_debug "Testing DNS resolution for www.torproject.org..."
      nslookup www.torproject.org || true
      log_debug "Testing DNS resolution through Tor..."
      curl --socks5-hostname $TOR_IP:$TOR_SOCKS_PORT -v https://check.torproject.org/ || true
    fi
    sleep $RETRY_DELAY
    retries=$((retries + 1))
  fi
done

if [ $download_success -eq 0 ]; then
  log_error "Failed to download Tor Browser after $MAX_RETRIES attempts"
  log_debug "Final connectivity test:"
  curl --socks5-hostname $TOR_IP:$TOR_SOCKS_PORT -v --connect-timeout 30 https://check.torproject.org/ || true
  exit 1
fi

log_info "Verifying archive format..."
if ! file /tmp/tor-browser.tar.xz | grep -q "XZ compressed"; then
  log_error "Downloaded file is not an XZ archive"
  exit 1
fi

log_info "Extracting..."
mkdir -p /opt/tor-browser
tar -xJf /tmp/tor-browser.tar.xz -C /opt/tor-browser --strip-components=1

log_info "Setting proper permissions..."
chmod -R 755 /opt/tor-browser

log_info "Done. Cleaning up..."
rm /tmp/tor-browser.tar.xz

log_info "Tor Browser $TOR_VER successfully installed!"
